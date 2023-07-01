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
  envoy_image     = data.terraform_remote_state.base.outputs.envoy_image
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
  static_client_agent_name = "consul-client-static-client${local.cluster_id.name_suffix}"
  static_client_proxy_name = "static-client-proxy${local.cluster_id.name_suffix}"
  static_server_agent_name = "consul-client-static-server${local.cluster_id.name_suffix}"
  static_server_proxy_name = "static-server-proxy${local.cluster_id.name_suffix}"
  static_server_name       = "static-server${local.cluster_id.name_suffix}"

  other_client_agent_name = "consul-client-other-client${local.cluster_id.name_suffix}"
  other_client_proxy_name = "other-client-proxy${local.cluster_id.name_suffix}"

}

provider "consul" {
  address    = local.api
  datacenter = local.datacenter
  token      = local.bootstrap_token
  ca_pem     = local.ca.certificate_bundle
}

resource "consul_acl_policy" "static_client_agent_read" {
  name  = "static-client-agent-read"
  rules = <<-RULE
    agent "${local.static_client_agent_name}" {
      policy = "read"
    }
    RULE
}

resource "consul_acl_policy" "other_client_agent_read" {
  name  = "other-client-agent-read"
  rules = <<-RULE
    agent "${local.other_client_agent_name}" {
      policy = "read"
    }
    RULE
}

resource "consul_acl_policy" "static_server_agent_read" {
  name  = "static-server-agent-read"
  rules = <<-RULE
    agent "${local.static_server_agent_name}" {
      policy = "read"
    }
    RULE
}

resource "consul_acl_token" "static_client_agent" {
  description = "Token for ${local.static_client_agent_name}"
  node_identities {
    node_name  = local.static_client_agent_name
    datacenter = local.datacenter
  }
}

resource "consul_acl_token" "other_client_agent" {
  description = "Token for ${local.other_client_agent_name}"
  node_identities {
    node_name  = local.other_client_agent_name
    datacenter = local.datacenter
  }
}

resource "consul_acl_token" "static_server_agent" {
  description = "Token for ${local.static_server_agent_name}"
  node_identities {
    node_name  = local.static_server_agent_name
    datacenter = local.datacenter
  }
}

resource "consul_acl_token" "static_client" {
  description = "Token for static-client"
  service_identities {
    service_name = "static-client"
  }
  policies = ["${consul_acl_policy.static_client_agent_read.name}"]
}

resource "consul_acl_token" "other_client" {
  description = "Token for other-client"
  service_identities {
    service_name = "other-client"
  }
  policies = ["${consul_acl_policy.other_client_agent_read.name}"]
}

resource "consul_acl_token" "static_server" {
  description = "Token for static-server"
  service_identities {
    service_name = "static-server"
  }
  policies = ["${consul_acl_policy.static_server_agent_read.name}"]
}

data "consul_acl_token_secret_id" "static_client" {
  accessor_id = consul_acl_token.static_client.id
}

data "consul_acl_token_secret_id" "other_client" {
  accessor_id = consul_acl_token.other_client.id
}

data "consul_acl_token_secret_id" "static_server" {
  accessor_id = consul_acl_token.static_server.id
}

data "consul_acl_token_secret_id" "static_client_agent" {
  accessor_id = consul_acl_token.static_client_agent.id
}

data "consul_acl_token_secret_id" "other_client_agent" {
  accessor_id = consul_acl_token.other_client_agent.id
}

data "consul_acl_token_secret_id" "static_server_agent" {
  accessor_id = consul_acl_token.static_server_agent.id
}

module "clients" {
  source = "../modules/clients"

  datacenter       = local.datacenter
  default_networks = [local.network]
  default_image    = local.consul_image.image_id
  default_config = {
    "agent-conf.hcl" = templatefile("${path.module}/config/client.hcl", {
      "datacenter" : local.datacenter,
      "gossip_key" : local.gossip_key,
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
      "name" : local.static_client_agent_name,
      "config" : {
        "static-client.hcl" : templatefile("${path.module}/services/static-client.hcl", {
          "token" : data.consul_acl_token_secret_id.static_client.secret_id
        })
        "acl-token.hcl" : templatefile("${path.module}/config/acl-token.hcl", {
          "agent_token" : data.consul_acl_token_secret_id.static_client_agent.secret_id
        })
      }
      "ports" : [
        {
          "internal" : 19000,
          "protocol" : "tcp",
        },
        {
          "internal" : 8080,
          "protocol" : "tcp",
        }
      ]
    },
    {
      "name" : local.other_client_agent_name,
      "config" : {
        "other-client.hcl" : templatefile("${path.module}/services/other-client.hcl", {
          "token" : data.consul_acl_token_secret_id.other_client.secret_id
        })
        "acl-token.hcl" : templatefile("${path.module}/config/acl-token.hcl", {
          "agent_token" : data.consul_acl_token_secret_id.other_client_agent.secret_id
        })
      }
      "ports" : [
        {
          "internal" : 19000,
          "protocol" : "tcp",
        },
        {
          "internal" : 8080,
          "protocol" : "tcp",
        }
      ]
    },
    {
      "name" : local.static_server_agent_name,
      "config" : {
        "static-server.hcl" : templatefile("${path.module}/services/static-server.hcl", {
          "token" : data.consul_acl_token_secret_id.static_server.secret_id
        })
        "acl-token.hcl" : templatefile("${path.module}/config/acl-token.hcl", {
          "agent_token" : data.consul_acl_token_secret_id.static_server_agent.secret_id
        })
      }
      "ports" : [
        {
          "internal" : 19000,
          "protocol" : "tcp",
        },
        {
          "internal" : 8080,
          "protocol" : "tcp",
        }
      ]
    }
  ]
}

module "static-server" {
  depends_on   = [module.clients]
  source       = "../modules/fortio"
  name         = local.static_server_name
  network_mode = "container:${local.static_server_agent_name}"
}

module "static-server-proxy" {
  depends_on = [module.clients]
  source     = "../modules/consul-envoy"

  consul_envoy_image = local.envoy_image.image_id
  name               = local.static_server_proxy_name
  consul_manager     = local.static_server_agent_name
  sidecar_for        = "static-server"
  expose_admin       = true

  env = [
    "CONSUL_HTTP_TOKEN=${data.consul_acl_token_secret_id.static_server.secret_id}",
    "CONSUL_GRPC_ADDR=http://localhost:8502"
  ]
}

module "static-client-proxy" {
  depends_on = [module.clients]
  source     = "../modules/consul-envoy"

  consul_envoy_image = local.envoy_image.image_id
  name               = local.static_client_proxy_name
  consul_manager     = local.static_client_agent_name
  sidecar_for        = "static-client"
  expose_admin       = true

  env = [
    "CONSUL_HTTP_TOKEN=${data.consul_acl_token_secret_id.static_client.secret_id}",
    "CONSUL_GRPC_ADDR=http://localhost:8502"
  ]
}


module "other-client-proxy" {
  depends_on = [module.clients]
  source     = "../modules/consul-envoy"

  consul_envoy_image = local.envoy_image.image_id
  name               = local.other_client_proxy_name
  consul_manager     = local.other_client_agent_name
  sidecar_for        = "other-client"
  expose_admin       = true

  env = [
    "CONSUL_HTTP_TOKEN=${data.consul_acl_token_secret_id.other_client.secret_id}",
    "CONSUL_GRPC_ADDR=http://localhost:8502"
  ]
}
