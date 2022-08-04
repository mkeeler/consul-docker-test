data "terraform_remote_state" "provisioning" {
  backend = "local"

  config = {
    path = "../provision/terraform.tfstate"
  }
}

