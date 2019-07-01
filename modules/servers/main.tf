locals {
   server_names = [
      for index, srv in var.servers:
      lookup(srv, "name", "${var.default_name_prefix}${var.datacenter}-${index}")
   ]
   server_hostnames = [
      for index, srv in var.servers:
      lookup(srv, "hostname", local.server_names[index])
   ]

   server_retry_joins = [
      for index, host in local.server_hostnames:
      formatlist("--retry-join=%s", concat(slice(local.server_hostnames, 0, index), slice(local.server_hostnames, index + 1, length(local.server_hostnames))))
   ]

   server_commands = [
      for index, srv in var.servers:
      concat(
         ["agent", "-datacenter=${var.datacenter}", "-server", "-client=0.0.0.0", "-bootstrap-expect=${length(var.servers)}"],
         local.server_retry_joins[index],
         lookup(srv, "extra_args", []),
         var.extra_args
      )
   ]

   server_uploads = [
      for srv in var.servers:
      merge(var.default_config, lookup(srv, "config", {}))
   ]

   server_ports = [
      for index, srv in var.servers:
      lookup(srv, "ports", [])
   ]

   server_images = [
      for srv in var.servers:
      lookup(srv, "image", var.default_image)
   ]

   server_networks = [
      for srv in var.servers:
      lookup(srv, "networks", var.default_networks)
   ]
}

resource "docker_volume" "server-data" {
  count = var.persistent_data ? length(var.servers) : 0
  name = "${local.server_names[count.index]}-data"
}

resource "docker_container" "server-containers" {
   count = length(var.servers)
   privileged = false
   image = local.server_images[count.index]
   name = local.server_names[count.index]
   hostname = local.server_hostnames[count.index]
   command = local.server_commands[count.index]
   env=var.env

   dynamic "networks_advanced" {
      for_each = local.server_networks[count.index]

      content {
         name = networks_advanced.value
      }
   }

   dynamic "upload" {
      for_each = local.server_uploads[count.index]

      content {
         content = upload.value
         file = "/consul/config/${upload.key}"
      }
   }

   dynamic "volumes" {
      for_each = var.persistent_data ? [docker_volume.server-data[count.index].name] : []

      content {
         volume_name = volumes.value
         container_path = "/consul/data/"
      }
   }

   dynamic "ports" {
      for_each = local.server_ports[count.index]

      content {
         internal = ports.value["internal"]
         external = contains(keys(ports.value), "external") ? ports.value["external"] : null
         protocol = contains(keys(ports.value), "protocol") ? ports.value["protocol"] : null
      }
   }
}