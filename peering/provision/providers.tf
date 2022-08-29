terraform {
  required_providers {
    consul = {
      source = "terraform.local/hashicorp/consul"
    }
    
    kubernetes = {
      source = "hashicorp/kubernetes"
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

provider "kubernetes" {
  alias          = "gamma"
  config_path    = pathexpand("~/.kube/config")
  config_context = local.gamma_k8s_context
}

provider "kubernetes" {
  alias          = "delta"
  config_path    = pathexpand("~/.kube/config")
  config_context = local.delta_k8s_context
}
