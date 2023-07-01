// This will allow usage of the outputs of the previous terraform run to be used
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "../secure-base/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "servers" {
  backend = "local"

  config = {
    path = "../secure-servers/terraform.tfstate.d/${terraform.workspace}/terraform.tfstate"
  }
}

// "Import" some of the other TF run outputs
locals {
  cluster_id      = data.terraform_remote_state.base.outputs.cluster_id
  license         = data.terraform_remote_state.base.outputs.license
  consul_image    = data.terraform_remote_state.base.outputs.consul_image
  ca              = data.terraform_remote_state.base.outputs.ca
  network         = data.terraform_remote_state.base.outputs.network
  gossip_key      = data.terraform_remote_state.base.outputs.gossip_key
  bootstrap_token = data.terraform_remote_state.base.outputs.bootstrap_token
  recovery_token  = data.terraform_remote_state.base.outputs.recovery_token
  datacenter      = data.terraform_remote_state.servers.outputs.datacenter
  server0Ports    = data.terraform_remote_state.servers.outputs.servers[0].ports
  server_join     = data.terraform_remote_state.servers.outputs.join
  api             = coalesce([for port in local.server0Ports : port.internal == 8501 ? "https://localhost:${port.external}" : ""]...)
}

locals {
  ui_name = "consul-ui${local.cluster_id.name_suffix}"
}

provider "consul" {
  address    = local.api
  datacenter = local.datacenter
  token      = local.bootstrap_token
  ca_pem     = local.ca.certificate_bundle
}

resource "consul_acl_token" "ui" {
  description = "Token for consul-ui agent"
  node_identities {
    node_name  = local.ui_name
    datacenter = local.datacenter
  }
}

data "consul_acl_token_secret_id" "ui" {
  accessor_id = consul_acl_token.ui.id
}

module "ui" {
  source = "../modules/clients"

  datacenter       = local.datacenter
  default_networks = [local.network]
  default_image    = local.consul_image.image_id
  default_config = {
    "agent-conf.hcl" = templatefile("${path.module}/config/client.hcl", {
      "datacenter" : local.datacenter,
      "gossip_key" : local.gossip_key,
      "agent_token" : data.consul_acl_token_secret_id.ui.secret_id
      "recovery_token" : local.recovery_token,
    })
  }
  default_name_include_dc = false
  default_name_suffix     = local.cluster_id.name_suffix

  extra_args = local.server_join

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

  clients = [
    {
      "name" : local.ui_name,
      "extra_args" : ["-ui"],
      "ports" : {
        "http" : {
          "internal" : 8501,
          "external" : 8501,
          "protocol" : "tcp",
        },
        "dns" : {
          "internal" : 8600,
          "external" : 8600,
          "protocol" : "udp",
        },
      }
    }
  ]
}
