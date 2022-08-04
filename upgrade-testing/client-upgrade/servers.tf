data "terraform_remote_state" "servers" {
  backend = "local"

  config = {
    path = "../server-upgrade/terraform.tfstate"
  }
}

locals {
  enterprise   = data.terraform_remote_state.servers.outputs.enterprise
  cluster_id   = data.terraform_remote_state.servers.outputs.cluster_id
  consul_image = data.terraform_remote_state.servers.outputs.consul_image
}
