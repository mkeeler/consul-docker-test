// This will allow usage of the outputs of the previous terraform run to be used
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../infra/terraform.tfstate"
  }
}

// Create locals to map to upstream outputs to make using them cleaner
locals {
  cluster_id        = data.terraform_remote_state.infra.outputs.cluster_id
  license           = data.terraform_remote_state.infra.outputs.license
  gamma_k8s_context = data.terraform_remote_state.infra.outputs.gamma_k8s_context
  delta_k8s_context = data.terraform_remote_state.infra.outputs.delta_k8s_context
  enterprise        = data.terraform_remote_state.infra.outputs.enterprise
  consul_image      = data.terraform_remote_state.infra.outputs.consul_image
  ca                = data.terraform_remote_state.infra.outputs.ca
  network           = data.terraform_remote_state.infra.outputs.network
  high_availability = data.terraform_remote_state.infra.outputs.high_availability
}
