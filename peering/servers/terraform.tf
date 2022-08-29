terraform {
  #   experiments = [module_variable_optional_attrs]

  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    random = {
      source = "hashicorp/random"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    k3d = {
      source  = "mkeeler/k3d"
      version = ">= 0.0.2"
    }
  }
  required_version = ">= 1.2.0"
}

provider "helm" {
  alias = "gamma"
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = local.gamma_k8s_context
  }
}

provider "kubernetes" {
  alias          = "gamma"
  config_path    = pathexpand("~/.kube/config")
  config_context = local.gamma_k8s_context
}

provider "helm" {
  alias = "delta"
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = local.delta_k8s_context
  }
}

provider "kubernetes" {
  alias          = "delta"
  config_path    = pathexpand("~/.kube/config")
  config_context = local.delta_k8s_context
}
