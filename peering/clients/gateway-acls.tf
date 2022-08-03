locals {
  alphaGatewayPartitions = toset([
    for key, gw in local.alphaGateways :
    gw.partition
  ])

  betaGatewayPartitions = toset([
    for key, gw in local.betaGateways :
    gw.partition
  ])
}

resource "consul_acl_policy" "alphaMeshWrite" {
  for_each  = local.alphaGatewayPartitions
  provider  = consul.alpha
  partition = each.value
  name      = "mesh-write"
  rules     = "mesh = \"write\""
}

resource "consul_acl_policy" "betaMeshWrite" {
  for_each  = local.betaGatewayPartitions
  provider  = consul.beta
  partition = each.value
  name      = "mesh-write"
  rules     = "mesh = \"write\""
}

resource "consul_acl_token" "alphaGatewayTokens" {
  for_each  = local.alphaGateways
  provider  = consul.alpha
  partition = each.value.partition
  service_identities {
    service_name = "mesh-gateway"
  }
  policies = [consul_acl_policy.alphaMeshWrite[each.value.partition].name]
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
  policies = [consul_acl_policy.betaMeshWrite[each.value.partition].name]
}

data "consul_acl_token_secret_id" "betaGatewaySecrets" {
  for_each    = consul_acl_token.betaGatewayTokens
  provider    = consul.beta
  accessor_id = each.value.accessor_id
  partition   = each.value.partition
}
