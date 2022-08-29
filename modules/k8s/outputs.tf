output "gossip_key" {
  value = local.gossip_key
}

output "helm_release" {
  value = helm_release.consul
}

output "ca" {
  value = local.cluster_ca
}
