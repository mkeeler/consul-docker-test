terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
  required_version = ">= 0.13"
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
