locals {
   client_names = [
      for index, client in var.clients:
      lookup(client, "name", "${var.default_name_prefix}${var.datacenter}-${index}")
   ]
   client_hostnames = [
      for index, client in var.clients:
      lookup(client, "hostname", local.client_names[index])
   ]

   client_commands = [
      for client in var.clients:
      concat(
         ["agent", "-datacenter=${var.datacenter}", "-client=0.0.0.0"],
         lookup(client, "extra_args", []),
         var.extra_args
      )
   ]

   client_uploads = [
      for client in var.clients:
      merge(var.default_config, lookup(client, "config", {}))
   ]

   client_ports = [
      for client in var.clients:
      lookup(client, "ports", [])
   ]

   client_images = [
      for client in var.clients:
      lookup(client, "image", var.default_image)
   ]

   client_networks = [
      for client in var.clients:
      lookup(client, "networks", var.default_networks)
   ]
}

resource "docker_volume" "client-data" {
  count = var.persistent_data ? length(var.clients) : 0
  name = "${local.client_names[count.index]}-data"
}

resource "docker_container" "client-containers" {
   count = length(var.clients)
   privileged = true
   image = local.client_images[count.index]
   name = local.client_names[count.index]
   hostname = local.client_hostnames[count.index]
   networks = local.client_networks[count.index]
   command = local.client_commands[count.index]
   env=["CONSUL_BIND_INTERFACE=eth0", "CONSUL_ALLOW_PRIVILEGED_PORTS=yes"]

   dynamic "upload" {
      for_each = local.client_uploads[count.index]

      content {
         content = upload.value
         file = "/consul/config/${upload.key}"
      }
   }

   dynamic "volumes" {
      for_each = var.persistent_data ? [docker_volume.client-data[count.index].name] : []

      content {
         volume_name = volumes.value
         container_path = "/consul/data"
      }
   }

   dynamic "ports" {
      for_each = local.client_ports[count.index]

      content {
         internal = ports.value["internal"]
         external = contains(keys(ports.value), "external") ? ports.value["external"] : null
         protocol = contains(keys(ports.value), "protocol") ? ports.value["protocol"] : null
      }
   }
}