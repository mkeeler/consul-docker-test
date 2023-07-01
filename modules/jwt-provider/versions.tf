terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }

    jwks = {
      source  = "iwarapter/jwks"
      version = "0.0.4"
    }
  }
  required_version = ">= 1.2"
}
