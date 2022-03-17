locals {   
   partial_name_dc = var.default_name_include_dc ? "${var.datacenter}-" : ""
   name_prefix = "${var.default_name_prefix}${local.partial_name_dc}"
   
   client_names = [
      for index, client in var.clients:
      lookup(client, "name", "${local.name_prefix}${index}${var.default_name_suffix}")
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

   cert_config = file("${path.module}/certs.hcl")
      
   client_uploads = [
      for client in var.clients:
      merge(var.default_config, lookup(client, "config", {}), var.tls_enabled ? {"certs.hcl": local.cert_config} : {})
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
   
   client_tls_dns_names = [
      for index, client in var.clients:
      concat(lookup(client, "tls_dns_names", []), [local.client_hostnames[index], "client.${var.datacenter}.consul", "localhost"])
   ]
}

resource "tls_private_key" "client_keys" {
   count = var.tls_enabled ? length(var.clients) : 0
   algorithm = "ECDSA"
   ecdsa_curve = "P384"
}

resource "tls_cert_request" "client_cert_reqs" {
   count = var.tls_enabled ? length(var.clients) : 0
   key_algorithm   = tls_private_key.client_keys[count.index].algorithm
   private_key_pem = tls_private_key.client_keys[count.index].private_key_pem
   
   dns_names = local.client_tls_dns_names[count.index]

   subject {
      common_name = "client.${var.datacenter}.consul"
      organization = var.tls_organization
      organizational_unit = var.tls_organizational_unit
      country = var.tls_country
      province = var.tls_province
      locality = var.tls_locality
      street_address = var.tls_street_address
      postal_code = var.tls_postal_code
  }
}

resource "tls_locally_signed_cert" "client_certs" {
   count = var.tls_enabled ? length(var.clients) : 0
   cert_request_pem   = tls_cert_request.client_cert_reqs[count.index].cert_request_pem
   ca_key_algorithm   = var.tls_ca_key_type
   ca_private_key_pem = var.tls_ca_key
   ca_cert_pem        = var.tls_ca_cert

   early_renewal_hours = 3

   validity_period_hours = var.tls_validity_days * 24

   allowed_uses = [
      "key_encipherment",
      "digital_signature",
      "client_auth",
      "server_auth",
   ]
   
   set_subject_key_id = true
}

locals {
   client_tls_uploads = [
      for index, srv in var.clients:
      var.tls_enabled ? {
         "cert.pem" = tls_locally_signed_cert.client_certs[index].cert_pem,
         "key.pem" = tls_private_key.client_keys[index].private_key_pem,
         "cacert.pem" = var.tls_ca_cert
      } : {}
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
   dynamic "networks_advanced" {
      for_each = local.client_networks[count.index]

      content {
         name = networks_advanced.value
      }
   }
   command = local.client_commands[count.index]
   env=var.env

   dynamic "upload" {
      for_each = local.client_uploads[count.index]

      content {
         content = upload.value
         file = "/consul/config/${upload.key}"
      }
   }
   
   dynamic "upload" {
      for_each = local.client_tls_uploads[count.index]

      content {
         content = upload.value
         file = "/consul/config/tls/${upload.key}"
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