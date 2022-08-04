terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    consul = {
      source = "hashicorp/consul"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 1.2.0"
}
