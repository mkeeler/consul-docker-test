locals {
  dns_names = var.disable_default_dns_names ? var.dns_names : concat(var.dns_names, ["consul", "localhost"])
}

resource "tls_private_key" "ca_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "root" {
  count           = var.root_ca == null ? 1 : 0
  private_key_pem = tls_private_key.ca_key.private_key_pem

  is_ca_certificate = true

  # Certificate expires after 12 hours.
  validity_period_hours = var.days * 24

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 3

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "crl_signing",
    "digital_signature",
    "cert_signing",
  ]

  set_subject_key_id = true

  dns_names = local.dns_names

  subject {
    common_name         = var.common_name
    organization        = var.organization
    organizational_unit = var.organizational_unit
    country             = var.country
    province            = var.province
    locality            = var.locality
    street_address      = var.street_address
    postal_code         = var.postal_code
    serial_number       = var.serial_number
  }
}


resource "tls_cert_request" "intermediate" {
  count           = var.root_ca != null ? 1 : 0
  private_key_pem = tls_private_key.ca_key.private_key_pem
  dns_names       = local.dns_names

  subject {
    common_name         = var.common_name
    organization        = var.organization
    organizational_unit = var.organizational_unit
    country             = var.country
    province            = var.province
    locality            = var.locality
    street_address      = var.street_address
    postal_code         = var.postal_code
  }
}

resource "tls_locally_signed_cert" "intermediate" {
  count                 = var.root_ca != null ? 1 : 0
  cert_request_pem      = tls_cert_request.intermediate[0].cert_request_pem
  ca_private_key_pem    = var.root_ca.private_key_pem
  ca_cert_pem           = var.root_ca.certificate_pem
  validity_period_hours = var.days * 24
  early_renewal_hours   = 3
  is_ca_certificate     = true

  allowed_uses = [
    "crl_signing",
    "digital_signature",
    "cert_signing",
  ]

  set_subject_key_id = true
}
