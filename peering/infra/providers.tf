terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    k3d = {
      source = "mkeeler/k3d"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.2.0"
}
