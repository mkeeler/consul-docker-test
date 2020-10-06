terraform {
  required_providers {
    docker = {
      source = "terraform-providers/docker"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.13"
}
