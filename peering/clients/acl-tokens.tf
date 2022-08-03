resource "random_uuid" "alphaRecoveryTokens" {
  for_each = local.alphaAgents
}

resource "consul_acl_token" "alphaAgentTokens" {
  for_each  = local.alphaAgents
  provider  = consul.alpha
  partition = each.value.partition
  node_identities {
    node_name  = each.value.name
    datacenter = "primary"
  }
}

data "consul_acl_token_secret_id" "alphaAgentSecrets" {
  for_each    = consul_acl_token.alphaAgentTokens
  provider    = consul.alpha
  accessor_id = each.value.accessor_id
  partition   = each.value.partition
}

resource "random_uuid" "betaRecoveryTokens" {
  for_each = local.betaAgents
}

resource "consul_acl_token" "betaAgentTokens" {
  for_each  = local.betaAgents
  provider  = consul.beta
  partition = each.value.partition
  node_identities {
    node_name  = each.value.name
    datacenter = "primary"
  }
}

data "consul_acl_token_secret_id" "betaAgentSecrets" {
  for_each    = consul_acl_token.betaAgentTokens
  provider    = consul.beta
  accessor_id = each.value.accessor_id
  partition   = each.value.partition
}
