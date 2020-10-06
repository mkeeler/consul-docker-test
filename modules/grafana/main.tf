data "docker_registry_image" "grafana" {
   name = "grafana/grafana"
}

locals {
   unique_postfix = var.unique_id != "" ? "-${var.unique_id}" : ""

   env = [
      for key, value in merge({"GF_SERVER_ROOT_URL"="http://localhost:3000", "GF_AUTH_ANONYMOUS_ENABLED"=true}, var.env):
      "${key}=${value}"
   ]

   ports = var.disable_host_port ? [] : [var.host_port]

   provisioning = [
      for provisioner in var.provisioning:
      {
         "content": provisioner.content,
         "file": "/etc/grafana/provisioning/${provisioner.type == "datasource" ? "datasources": "dashboards"}/${provisioner.name}"
      }
      if provisioner.type == "datasource" || provisioner.type == "dashboard"
   ]
}

resource "docker_image" "grafana" {
   name          = data.docker_registry_image.grafana.name
   pull_triggers = [data.docker_registry_image.grafana.sha256_digest]
   keep_locally = true
}

resource "docker_volume" "grafana-storage" {
   name = "${var.container_name}-storage${local.unique_postfix}"
}

// grafana
resource "docker_container" "grafana" {
   image = docker_image.grafana.name
   name = "${var.container_name}${local.unique_postfix}"
   hostname = var.container_name
   dynamic "networks_advanced" {
      for_each = var.networks

      content {
         name = networks_advanced.value
      }
   }
   networks = var.networks

   env = local.env

   volumes {
      volume_name = docker_volume.grafana-storage.name
      container_path = "/var/lib/grafana"
   }

   dynamic "ports" {
      for_each = local.ports
      content {
         internal = 3000
         external = ports.value
         protocol = "tcp"
      }
   }

   dynamic "upload" {
      for_each = local.provisioning

      content {
         content = upload.value.content
         file = upload.value.file
      }

   }
}
