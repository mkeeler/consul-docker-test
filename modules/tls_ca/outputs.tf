output "private_key_pem" {
  sensitive = true
  value     = tls_private_key.ca_key.private_key_pem
}

output "certificate_pem" {
  value = var.root_ca == null ? tls_self_signed_cert.root[0].cert_pem : tls_locally_signed_cert.intermediate[0].cert_pem
}

output "certificate_bundle" {
  value = var.root_ca == null ? tls_self_signed_cert.root[0].cert_pem : join("\n", [tls_locally_signed_cert.intermediate[0].cert_pem, var.root_ca.certificate_bundle])
}
