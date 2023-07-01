output "private_key_pem" {
  sensitive = true
  value     = tls_private_key.ca_key.private_key_pem
}

output "public_key_pem" {
  value = tls_private_key.ca_key.public_key_pem
}

output "certificate_pem" {
  value = var.root_ca == null ? tls_self_signed_cert.root[0].cert_pem : tls_locally_signed_cert.intermediate[0].cert_pem
}

output "certificate_bundle" {
  value = var.root_ca == null ? tls_self_signed_cert.root[0].cert_pem : join("\n", [tls_locally_signed_cert.intermediate[0].cert_pem, var.root_ca.certificate_bundle])
}

output "params" {
  value = {
    "organization" : var.organization,
    "organizational_unit" : var.organizational_unit,
    "country" : var.country,
    "province" : var.province,
    "locality" : var.locality,
    "street_address" : var.street_address,
    "postal_code" : var.postal_code,
    "serial_number" : var.serial_number,
    "dns_names" : var.dns_names,
    "common_name" : var.common_name,
    "days" : var.days,
  }
}
