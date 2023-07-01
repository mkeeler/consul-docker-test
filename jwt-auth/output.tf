output "p1token" {
  value     = module.p1token.token
  sensitive = true
}

output "p2token" {
  value     = module.p2token.token
  sensitive = true
}

output "p1jwks" {
  value = module.provider1.jwks
}

output "p2jwks" {
  value = module.provider2.jwks
}
