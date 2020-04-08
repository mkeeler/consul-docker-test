output "key" {
  value = tls_private_key.ca_key
}

output "cert" {
   value = tls_self_signed_cert.ca_cert
}