locals {
  clusterNames    = ["alpha", "beta"]
  exposedAPIPorts = [8501, 9501]

  default_image = var.consul_image != "" ? var.consul_image : var.enterprise ? "hashicorp/consul-enterprise:local" : "consul:local"
}

resource "docker_image" "consul" {
  name         = local.default_image
  keep_locally = true
}

resource "random_id" "gossip_keys" {
  count       = 2
  byte_length = 32
}

resource "random_uuid" "management_tokens" {
  count = 2
}

resource "random_uuid" "recovery_tokens" {
  count = 2
}

module "certificate_authorities" {
  count  = 2
  source = "../../modules/tls_ca"

  days        = 30
  common_name = "Consul Cluster ${local.clusterNames[count.index]}${local.cluster_id} CA"
}

module "clusters" {
  count  = 2
  source = "../../modules/servers"

  persistent_data         = true
  datacenter              = "primary"
  default_networks        = [docker_network.network.name]
  default_image           = docker_image.consul.latest
  default_name_prefix     = "consul-${local.clusterNames[count.index]}-"
  default_name_suffix     = local.cluster_id_suffix
  default_name_include_dc = false
  default_config = {
    "ports.hcl"        = file("consul-configs/ports.hcl")
    "tls.hcl"          = file("consul-configs/tls.hcl")
    "connect.hcl"      = file("consul-configs/connect.hcl")
    "gossip.hcl"       = templatefile("consul-configs/gossip.hcl", { "gossip_key" : random_id.gossip_keys[count.index].b64_std })
    "acl.hcl"          = templatefile("consul-configs/acl.hcl", { "management" : random_uuid.management_tokens[count.index].result, "recovery" : random_uuid.recovery_tokens[count.index].result })
    "peering.hcl"      = file("consul-configs/peering.hcl")
    "auto-encrypt.hcl" = file("consul-configs/auto-encrypt.hcl")
  }

  env = module.license.license_docker_env

  tls_enabled    = true
  tls_ca_cert    = module.certificate_authorities[count.index].cert.cert_pem
  tls_ca_key     = module.certificate_authorities[count.index].key.private_key_pem
  use_tls_stanza = true

  labels = {
    "consul" : "server",
    "consul_tf_id" : local.cluster_id_raw,
    "consul_cluster_name" : local.clusterNames[count.index],
  }

  # 3 servers all with defaults
  servers = [{
    "extra_args" : ["-ui"],
    "ports" : {
      "http" : {
        "internal" : 8501,
        "external" : local.exposedAPIPorts[count.index],
        "protocol" : "tcp",
      }
    }
  }, {}, {}]
}
