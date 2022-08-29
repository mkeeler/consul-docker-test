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
  alpha_token   = data.terraform_remote_state.servers.outputs.alpha_token
  beta_token    = data.terraform_remote_state.servers.outputs.beta_token
  alpha_ca_cert = data.terraform_remote_state.servers.outputs.alpha_ca_cert
  beta_ca_cert  = data.terraform_remote_state.servers.outputs.beta_ca_cert

  enterprise  = data.terraform_remote_state.servers.outputs.enterprise
  gamma_k8s_context = data.terraform_remote_state.servers.outputs.gamma_k8s_context
  delta_k8s_context = data.terraform_remote_state.servers.outputs.delta_k8s_context
}
