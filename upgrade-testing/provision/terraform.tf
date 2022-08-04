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
