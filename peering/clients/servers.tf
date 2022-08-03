# This will allow usage of the outputs of the previous terraform run to create/provision the servers
data "terraform_remote_state" "servers" {
  backend = "local"

  config = {
    path = "../servers/terraform.tfstate"
  }
}
