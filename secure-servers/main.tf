// This will allow usage of the outputs of the previous terraform run to be used
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "../secure-base/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

// Create locals to map to upstream outputs to make using them cleaner
locals {
  cluster_id      = data.terraform_remote_state.base.outputs.cluster_id
  license         = data.terraform_remote_state.base.outputs.license
  consul_image    = data.terraform_remote_state.base.outputs.consul_image
  ca              = data.terraform_remote_state.base.outputs.ca
  network         = data.terraform_remote_state.base.outputs.network
  gossip_key      = data.terraform_remote_state.base.outputs.gossip_key
  bootstrap_token = data.terraform_remote_state.base.outputs.bootstrap_token
  recovery_token  = data.terraform_remote_state.base.outputs.recovery_token
}

module "servers" {
  source = "../modules/servers"

  persistent_data  = true
  datacenter       = var.datacenter
  default_networks = [local.network]
  default_image    = local.consul_image.image_id
  default_config = {
    "agent-conf.hcl" = templatefile("${path.module}/config/server.hcl", {
      "datacenter" : var.datacenter,
      "gossip_key" : local.gossip_key,
      "bootstrap_token" : local.bootstrap_token,
      "recovery_token" : local.recovery_token,
    })
  }
  default_name_include_dc = false
  default_name_suffix     = local.cluster_id.name_suffix
  enable_healthcheck      = true

  env = local.license.license_docker_env

  labels = local.cluster_id.resource_labels

  tls_enabled             = true
  tls_ca_cert             = local.ca.certificate_bundle
  tls_ca_key              = local.ca.private_key_pem
  tls_organization        = local.ca.params.organization
  tls_organizational_unit = local.ca.params.organizational_unit
  tls_country             = local.ca.params.country
  tls_province            = local.ca.params.province
  tls_locality            = local.ca.params.locality
  tls_street_address      = local.ca.params.street_address
  tls_postal_code         = local.ca.params.postal_code

  # All servers use the defaults defaults
  servers = [for i, v in range(var.num_servers) : {
    "ports" : {
      "https" : {
        "internal" : 8501,
        "protocol" : "tcp"
      },
      "grpc_tls" : {
        "internal" : 8503,
        "protocol" : "tcp"
      },
    }
  }]
}
