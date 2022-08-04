data "terraform_remote_state" "original" {
  backend = "local"

  config = {
    path = "../original-servers/terraform.tfstate"
  }
}

locals {
  enterprise   = data.terraform_remote_state.original.outputs.enterprise
  cluster_id   = data.terraform_remote_state.original.outputs.cluster_id
  consul_image = data.terraform_remote_state.original.outputs.consul_image
}
