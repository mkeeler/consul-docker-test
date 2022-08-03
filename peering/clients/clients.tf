locals {

  alphaEnterpriseGateways = {
    "alpha-foo-gateway" : {
      "name" : "consul-alpha-foo-gateway${local.cluster_id_suffix}"
      "config" : {
        "partition.hcl" : "partition = \"foo\""
      },
      "partition" : "foo"
    }
  }

  betaEnterpriseGateways = {
    "beta-bar-gateway" : {
      "name" : "consul-beta-bar-gateway${local.cluster_id_suffix}"
      "config" : {
        "partition.hcl" : "partition = \"foo\""
      },
      "partition" : "bar"
    }
  }

  alphaOssGateways = {
    "alpha-default-gateway" : {
      "name" : "consul-alpha-default-gateway${local.cluster_id_suffix}"
      "config" : {},
      "partition" : ""
    }
  }

  betaOssGateways = {
    "beta-default-gateway" : {
      "name" : "consul-beta-default-gateway${local.cluster_id_suffix}"
      "config" : {},
      "partition" : ""
    }
  }

  alphaGateways = merge(
    local.alphaOssGateways,
  data.terraform_remote_state.servers.outputs.enterprise ? local.alphaEnterpriseGateways : {})

  betaGateways = merge(
    local.betaOssGateways,
  data.terraform_remote_state.servers.outputs.enterprise ? local.betaEnterpriseGateways : {})

  alphaAgents = local.alphaGateways
  betaAgents  = local.betaGateways
}

resource "docker_image" "consul" {
  name         = data.terraform_remote_state.servers.outputs.consul_image
  keep_locally = true
}

module "alpha_clients" {
  source = "../../modules/clients"

  persistent_data = true
  datacenter      = "primary"
  default_config = {
    "ports.hcl"        = file("consul-configs/ports.hcl")
    "tls.hcl"          = file("consul-configs/tls.hcl")
    "connect.hcl"      = file("consul-configs/connect.hcl")
    "gossip.hcl"       = templatefile("consul-configs/gossip.hcl", { "gossip_key" : data.terraform_remote_state.servers.outputs.alpha_gossip_key })
    "peering.hcl"      = file("consul-configs/peering.hcl")
    "auto-encrypt.hcl" = file("consul-configs/auto-encrypt.hcl")
    "tls/ca.pem"       = data.terraform_remote_state.servers.outputs.alpha_ca_cert
  }
  default_name_prefix     = "consul-alpha-client"
  default_name_suffix     = local.cluster_id_suffix
  default_networks        = [data.terraform_remote_state.servers.outputs.network]
  default_image           = docker_image.consul.latest
  extra_args              = data.terraform_remote_state.servers.outputs.alpha_join
  default_name_include_dc = false

  env = module.license.license_docker_env

  clients = [
    for key, agent in local.alphaAgents :
    {
      "name" : "${agent.name}",
      "config" : merge(agent["config"], {
        "acl.hcl" : templatefile("consul-configs/acl.hcl", { "agent" : data.consul_acl_token_secret_id.alphaAgentSecrets[key].secret_id, "recovery" : random_uuid.alphaRecoveryTokens[key].result })
      })
    }
  ]
}

module "beta_clients" {
  source = "../../modules/clients"

  persistent_data = true
  datacenter      = "primary"
  default_config = {
    "ports.hcl"        = file("consul-configs/ports.hcl")
    "tls.hcl"          = file("consul-configs/tls.hcl")
    "connect.hcl"      = file("consul-configs/connect.hcl")
    "gossip.hcl"       = templatefile("consul-configs/gossip.hcl", { "gossip_key" : data.terraform_remote_state.servers.outputs.beta_gossip_key })
    "peering.hcl"      = file("consul-configs/peering.hcl")
    "auto-encrypt.hcl" = file("consul-configs/auto-encrypt.hcl")
    "tls/ca.pem"       = data.terraform_remote_state.servers.outputs.beta_ca_cert
  }
  default_name_prefix     = "consul-beta-client"
  default_name_suffix     = local.cluster_id_suffix
  default_networks        = [data.terraform_remote_state.servers.outputs.network]
  default_image           = docker_image.consul.latest
  default_name_include_dc = false
  extra_args              = data.terraform_remote_state.servers.outputs.beta_join

  env = module.license.license_docker_env

  clients = [
    for key, agent in local.betaAgents :
    {
      "name" : "${agent.name}",
      "config" : merge(agent["config"], {
        "acl.hcl" : templatefile("consul-configs/acl.hcl", { "agent" : data.consul_acl_token_secret_id.betaAgentSecrets[key].secret_id, "recovery" : random_uuid.betaRecoveryTokens[key].result })
      })
    }
  ]
}
