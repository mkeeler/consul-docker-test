# This will allow usage of the outputs of the previous terraform run to create/provision the servers
data "terraform_remote_state" "servers" {
  backend = "local"

  config = {
    path = "../servers/terraform.tfstate"
  }
}

# Create locals to map to upstream outputs to make using them cleaner
locals {
  alpha_api     = data.terraform_remote_state.servers.outputs.alpha_api
  beta_api      = data.terraform_remote_state.servers.outputs.beta_api
  alpha_join     = data.terraform_remote_state.servers.outputs.alpha_join
  beta_join      = data.terraform_remote_state.servers.outputs.beta_join
  alpha_token   = data.terraform_remote_state.servers.outputs.alpha_token
  beta_token    = data.terraform_remote_state.servers.outputs.beta_token
  alpha_ca_cert = data.terraform_remote_state.servers.outputs.alpha_ca_cert
  beta_ca_cert  = data.terraform_remote_state.servers.outputs.beta_ca_cert
  alpha_gossip_key = data.terraform_remote_state.servers.outputs.alpha_gossip_key
  beta_gossip_key  = data.terraform_remote_state.servers.outputs.beta_gossip_key
  
  enterprise  = data.terraform_remote_state.servers.outputs.enterprise
  gamma_k8s_context = data.terraform_remote_state.servers.outputs.gamma_k8s_context
  delta_k8s_context = data.terraform_remote_state.servers.outputs.delta_k8s_context
  license = data.terraform_remote_state.servers.outputs.license
  consul_image = data.terraform_remote_state.servers.outputs.consul_image
  network = data.terraform_remote_state.servers.outputs.network
  cluster_id = data.terraform_remote_state.servers.outputs.cluster_id
}
