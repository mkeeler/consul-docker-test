locals {
  use_segments = length(var.segments) > 0

  healthcheck_content = var.enable_healthcheck ? "curl -s -k ${var.healthcheck_endpoint}/v1/status/leader | xargs test -n" : "/bin/true"

  partial_name_dc = var.default_name_include_dc ? "${var.datacenter}-" : ""
  name_prefix     = "${var.default_name_prefix}${local.partial_name_dc}"

  server_names = [
    for index, srv in var.servers :
    lookup(srv, "name", "${local.name_prefix}${index}${var.default_name_suffix}")
  ]
  server_hostnames = [
    for index, srv in var.servers :
    lookup(srv, "hostname", local.server_names[index])
  ]

  server_retry_joins = [
    for index, host in local.server_hostnames :
    formatlist("--retry-join=%s", concat(slice(local.server_hostnames, 0, index), slice(local.server_hostnames, index + 1, length(local.server_hostnames))))
  ]

  server_commands = [
    for index, srv in var.servers :
    concat(
      ["agent", "-datacenter=${var.datacenter}", "-server", "-client=0.0.0.0"],
      var.bootstrap == true ? ["-bootstrap-expect=${var.bootstrap_expect > 0 ? var.bootstrap_expect : length(var.servers)}"] : [],
      local.server_retry_joins[index],
      lookup(srv, "extra_args", []),
      var.extra_args
    )
  ]

  cert_config = file("${path.module}/certs.hcl")

  segment_list = [
    for name, segment_config in var.segments :
    merge({ "name" : name }, segment_config)
  ]

  segment_config = local.use_segments ? templatefile("${path.module}/segment-conf.hcl", { "segments" : local.segment_list }) : ""

  server_uploads = [
    for srv in var.servers :
    merge(var.default_config,
      lookup(srv, "config", {}),
      var.tls_enabled ? { "certs.hcl" : local.cert_config } : {},
    local.use_segments ? { "segment-conf.hcl" : local.segment_config } : {})
  ]

  server_ports = [
    for index, srv in var.servers :
    lookup(srv, "ports", [])
  ]

  server_images = [
    for srv in var.servers :
    lookup(srv, "image", var.default_image)
  ]

  server_networks = [
    for srv in var.servers :
    lookup(srv, "networks", var.default_networks)
  ]

  server_tls_dns_names = [
    for srv in var.servers :
    concat(lookup(srv, "tls_dns_names", []), ["server.${var.datacenter}.consul", "localhost"])
  ]
}

resource "tls_private_key" "server_keys" {
  count       = var.tls_enabled ? length(var.servers) : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "server_cert_reqs" {
  count           = var.tls_enabled ? length(var.servers) : 0
  key_algorithm   = tls_private_key.server_keys[count.index].algorithm
  private_key_pem = tls_private_key.server_keys[count.index].private_key_pem

  dns_names = local.server_tls_dns_names[count.index]

  subject {
    common_name         = local.server_hostnames[count.index]
    organization        = var.tls_organization
    organizational_unit = var.tls_organizational_unit
    country             = var.tls_country
    province            = var.tls_province
    locality            = var.tls_locality
    street_address      = var.tls_street_address
    postal_code         = var.tls_postal_code
  }
}

resource "tls_locally_signed_cert" "server_certs" {
  count              = var.tls_enabled ? length(var.servers) : 0
  cert_request_pem   = tls_cert_request.server_cert_reqs[count.index].cert_request_pem
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
  server_tls_uploads = [
    for index, srv in var.servers :
    var.tls_enabled ? {
      "cert.pem"   = tls_locally_signed_cert.server_certs[index].cert_pem,
      "key.pem"    = tls_private_key.server_keys[index].private_key_pem,
      "cacert.pem" = var.tls_ca_cert
    } : {}
  ]
}

resource "docker_volume" "server-data" {
  count = var.persistent_data ? length(var.servers) : 0
  name  = "${local.server_names[count.index]}-data"
}

resource "docker_container" "server-containers" {
  count      = length(var.servers)
  privileged = false
  image      = local.server_images[count.index]
  name       = local.server_names[count.index]
  hostname   = local.server_hostnames[count.index]
  command    = local.server_commands[count.index]
  env        = var.env

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
      file    = "/consul/config/${upload.key}"
    }
  }

  dynamic "upload" {
    for_each = local.server_tls_uploads[count.index]

    content {
      content = upload.value
      file    = "/consul/config/tls/${upload.key}"
    }
  }

  dynamic "volumes" {
    for_each = var.persistent_data ? [docker_volume.server-data[count.index].name] : []

    content {
      volume_name    = volumes.value
      container_path = "/consul/data/"
      read_only      = false
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

  upload {
    file       = "/container-health"
    content    = local.healthcheck_content
    executable = true
  }

  healthcheck {
    test     = ["CMD", "/bin/sh", "-c", "/container-health"]
    interval = "1s"
  }
}
