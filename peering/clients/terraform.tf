terraform {
  required_providers {
    consul = {
      source = "hashicorp/consul"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.2.0"
}

provider "consul" {
  alias      = "alpha"
  address    = data.terraform_remote_state.servers.alpha_api
  ca_pem     = data.terraform_remote_state.servers.alpha_ca_cert
  token      = data.terraform_remote_state.servers.alpha_token
  datacenter = "primary"
}

provider "consul" {
  alias      = "beta"
  address    = data.terraform_remote_state.servers.beta_api
  ca_pem     = data.terraform_remote_state.servers.beta_ca_cert
  token      = data.terraform_remote_state.servers.beta_token
  datacenter = "primary"
}
