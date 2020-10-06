terraform {
  required_providers {
    docker = {
      source = "terraform-providers/docker"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}
