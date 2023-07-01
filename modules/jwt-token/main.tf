resource "jwt_signed_token" "token" {
  algorithm   = var.algorithm
  claims_json = var.claims_json
  key         = var.key
}
