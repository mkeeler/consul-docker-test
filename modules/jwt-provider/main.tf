locals {
  rsa_algorithms   = ["RS256", "RS384", "RS512"]
  ecdsa_algorithms = ["ES256", "ES384", "ES512"]
  rsa              = contains(local.rsa_algorithms, var.algorithm)
}

resource "tls_private_key" "key" {
  algorithm   = local.rsa ? "RSA" : "ECDSA"
  ecdsa_curve = local.rsa ? null : "P384"
  rsa_bits    = local.rsa ? 4096 : null
}

data "jwks_from_key" "jwks" {
  key = tls_private_key.key.public_key_pem
}
