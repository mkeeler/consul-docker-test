resource "consul_acl_token" "alphaGatewayTokens" {
  for_each  = local.alphaGateways
  provider  = consul.alpha
  partition = each.value.partition
  service_identities {
    service_name = "mesh-gateway"
  }
}

data "consul_acl_token_secret_id" "alphaGatewaySecrets" {
  for_each    = consul_acl_token.alphaGatewayTokens
  provider    = consul.alpha
  accessor_id = each.value.accessor_id
  partition   = each.value.partition
}

resource "consul_acl_token" "betaGatewayTokens" {
  for_each  = local.betaGateways
  provider  = consul.beta
  partition = each.value.partition
  service_identities {
    service_name = "mesh-gateway"
  }
}

data "consul_acl_token_secret_id" "betaGatewaySecrets" {
  for_each    = consul_acl_token.betaGatewayTokens
  provider    = consul.beta
  accessor_id = each.value.accessor_id
  partition   = each.value.partition
}
