terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.13"
}
