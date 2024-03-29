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
  address    = local.alpha_api
  ca_pem     = local.alpha_ca_cert
  token      = local.alpha_token
  datacenter = "primary"
}

provider "consul" {
  alias      = "beta"
  address    = local.beta_api
  ca_pem     = local.beta_ca_cert
  token      = local.beta_token
  datacenter = "primary"
}

