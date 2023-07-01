module "provider1" {
  source = "../modules/jwt-provider"

  algorithm = "ES384"
}

module "provider2" {
  source = "../modules/jwt-provider"

  algorithm = "ES384"
}

module "p1token" {
  source = "../modules/jwt-token"

  algorithm = module.provider1.algorithm
  key       = module.provider1.private_key_pem
  claims_json = jsonencode({
    "iss" : "https://provider1.consul.internal"
  })
}

module "p2token" {
  source = "../modules/jwt-token"

  algorithm = module.provider2.algorithm
  key       = module.provider2.private_key_pem
  claims_json = jsonencode({
    "iss" : "https://provider2.consul.internal"
  })
}

resource "local_file" "p1" {
  filename = "${path.module}/${terraform.workspace}/p1.hcl"
  content = templatefile("${path.module}/provider.hcl", {
    "name" : "provider1",
    "issuer" : "https://provider1.consul.internal",
    "jwks" : module.provider1.jwks
  })
}

resource "local_file" "p2" {
  filename = "${path.module}/${terraform.workspace}/p2.hcl"
  content = templatefile("${path.module}/provider.hcl", {
    "name" : "provider2",
    "issuer" : "https://provider2.consul.internal",
    "jwks" : module.provider2.jwks
  })
}
