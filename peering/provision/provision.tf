# create the necessary partitions in the alpha cluster
resource "consul_admin_partition" "alpha" {
  provider = consul.alpha
  name     = "foo"
}

# create the neessary partitions in the beta cluster
resource "consul_admin_partition" "beta" {
  provider = consul.beta
  name     = "bar"
}

resource "consul_peering_token" "alpha_peering_tokens" {
  for_each = {for name, info in local.peerings: name => info if info.acceptor.cluster == "alpha"}
  provider = consul.alpha
  peer_name = format("%s-%s", each.value.dialer.cluster, each.value.dialer.partition != "" ? each.value.dialer.partition : "default")
  partition = each.value.acceptor.partition
}

resource "consul_peering_token" "beta_peering_tokens" {
  for_each = {for name, info in local.peerings: name => info if info.acceptor.cluster == "beta"}
  provider = consul.beta
  peer_name = format("%s-%s", each.value.dialer.cluster, each.value.dialer.partition != "" ? each.value.dialer.partition : "default")
  partition = each.value.acceptor.partition
}

module "gamma_peering_tokens" {
  for_each = {for name, info in local.peerings: name => info if info.acceptor.cluster == "gamma" }
  providers = {
    kubernetes = kubernetes.gamma
  }
  source = "../../modules/k8s-peering-acceptor"
  peer_name = format("%s-%s", each.value.dialer.cluster, each.value.dialer.partition != "" ? each.value.dialer.partition : "default")
  namespace = "consul"
}

module "delta_peering_tokens" {
  for_each = {for name, info in local.peerings: name => info if info.acceptor.cluster == "delta" }
  providers = {
    kubernetes = kubernetes.delta
  }
  source = "../../modules/k8s-peering-acceptor"
  peer_name = format("%s-%s", each.value.dialer.cluster, each.value.dialer.partition != "" ? each.value.dialer.partition : "default")
  namespace = "consul"
}

locals {
  peering_tokens = {
    for name, info in local.peerings:
    name => info.acceptor.cluster == "alpha" ? consul_peering_token.alpha_peering_tokens[name].peering_token :
      info.acceptor.cluster == "beta" ? consul_peering_token.beta_peering_tokens[name].peering_token :
      info.acceptor.cluster == "gamma" ? module.gamma_peering_tokens[name].peering_token :
      module.delta_peering_tokens[name].peering_token
  }
}

resource "consul_peering" "alpha_peerings" {
  for_each = {for name, info in local.peerings: name => info if info.dialer.cluster == "alpha"}
  provider = consul.alpha
  peer_name = format("%s-%s", each.value.acceptor.cluster, each.value.acceptor.partition != "" ? each.value.acceptor.partition : "default")
  partition = each.value.dialer.partition
  peering_token = local.peering_tokens[each.key]
}

resource "consul_peering" "beta_peerings" {
  for_each = {for name, info in local.peerings: name => info if info.dialer.cluster == "beta"}
  provider = consul.beta
  peer_name = format("%s-%s", each.value.acceptor.cluster, each.value.acceptor.partition != "" ? each.value.acceptor.partition : "default")
  partition = each.value.dialer.partition
  peering_token = local.peering_tokens[each.key]
}

module "gamma_peerings" {
  source = "../../modules/k8s-peering-dialer"
  for_each = {for name, info in local.peerings: name => info if info.dialer.cluster == "gamma"}
  providers = {
    kubernetes = kubernetes.gamma
  }
  peer_name = format("%s-%s", each.value.acceptor.cluster, each.value.acceptor.partition != "" ? each.value.acceptor.partition : "default")
  namespace = "consul"
  peering_token = local.peering_tokens[each.key]
}

module "delta_peerings" {
  source = "../../modules/k8s-peering-dialer"
  for_each = {for name, info in local.peerings: name => info if info.dialer.cluster == "delta"}
  providers = {
    kubernetes = kubernetes.delta
  }
  peer_name = format("%s-%s", each.value.acceptor.cluster, each.value.acceptor.partition != "" ? each.value.acceptor.partition : "default")
  namespace = "consul"
  peering_token = local.peering_tokens[each.key]
}

