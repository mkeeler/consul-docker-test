data "docker_registry_image" "prometheus" {
   name = "prom/prometheus"
}

locals {
   unique_postfix = var.unique_id != "" ? "-${var.unique_id}" : ""

   ports = var.disable_host_port ? [] : [var.host_port]
}

resource "docker_image" "prometheus" {
   name          = data.docker_registry_image.prometheus.name
   pull_triggers = [data.docker_registry_image.prometheus.sha256_digest]
   keep_locally = true
}

resource "docker_volume" "prometheus-data" {
   name = "${var.container_name}-data${local.unique_postfix}"
}


resource "docker_container" "prometheus" {
   image = docker_image.prometheus.name
   name = "${var.container_name}${local.unique_postfix}"
   hostname = "${var.container_name}${local.unique_postfix}"
   dynamic "networks_advanced" {
      for_each = var.networks

      content {
         name = networks_advanced.value
      }
   }

   dynamic "ports" {
      for_each = local.ports
      content {
         internal = 9090
         external = ports.value
         protocol = "tcp"
      }
   }

   dynamic "upload" {
      for_each = var.config != "" ? [var.config] : []

      content {
         content = upload.value
         file = "/etc/prometheus/prometheus.yml"
      }

   }

   volumes {
      volume_name = docker_volume.prometheus-data.name
      container_path  = "/prometheus"
   }


}