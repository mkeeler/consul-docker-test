output "private_key_pem" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "public_key_pem" {
  value = tls_private_key.key.public_key_pem
}

output "jwks" {
  value = jsonencode({ "keys" : [jsondecode(data.jwks_from_key.jwks.jwks)] })
}

output "algorithm" {
  value = var.algorithm
}
