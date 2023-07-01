output "license" {
  value = module.license
}

output "cluster_id" {
  value = module.cluster_id
}

output "consul_image" {
  value = docker_image.consul
}

output "envoy_image" {
  value = docker_image.envoy
}

output "ca" {
  sensitive = true
  value     = module.certificate_authority
}

output "network" {
  value = docker_network.consul.name
}

output "bootstrap_token" {
  value     = random_uuid.bootstrap_token.result
  sensitive = true
}

output "recovery_token" {
  value     = random_uuid.recovery_token.result
  sensitive = true
}

output "gossip_key" {
  value = random_id.gossip_key.b64_std
}
