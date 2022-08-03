terraform {
  required_providers {
    consul = {
      source  = "terraform.local/hashicorp/consul"
      version = "2.15.1"
    }
    random = {
      source = "hashicorp/random"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 1.2.0"
}

provider "consul" {
  alias      = "alpha"
  address    = data.terraform_remote_state.servers.outputs.alpha_api
  ca_pem     = data.terraform_remote_state.servers.outputs.alpha_ca_cert
  token      = data.terraform_remote_state.servers.outputs.alpha_token
  datacenter = "primary"
}

provider "consul" {
  alias      = "beta"
  address    = data.terraform_remote_state.servers.outputs.beta_api
  ca_pem     = data.terraform_remote_state.servers.outputs.beta_ca_cert
  token      = data.terraform_remote_state.servers.outputs.beta_token
  datacenter = "primary"
}
