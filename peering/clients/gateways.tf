resource "docker_image" "envoy" {
  name         = "consul-envoy"
  keep_locally = true
}

module "alpha_gateways" {
  for_each = local.alphaGateways

  depends_on = [module.alpha_clients]

  source = "../../modules/consul-envoy"

  consul_envoy_image       = docker_image.envoy.latest
  name                     = "envoy-${each.key}${local.cluster_id_suffix}"
  consul_manager           = local.alphaGateways[each.key].name
  container_network_inject = true
  mesh_gateway             = true
  register                 = true
  expose_admin             = true
  bind_addresses           = { "default" : "0.0.0.0:8443" }

  env = concat(module.license.license_docker_env, [
    "CONSUL_HTTP_TOKEN=${data.consul_acl_token_secret_id.alphaGatewaySecrets[each.key].secret_id}"
  ])
}

module "beta_gateways" {
  for_each = local.betaGateways

  depends_on = [module.beta_clients]

  source = "../../modules/consul-envoy"

  consul_envoy_image       = docker_image.envoy.latest
  name                     = "envoy-${each.key}${local.cluster_id_suffix}"
  consul_manager           = local.betaGateways[each.key].name
  container_network_inject = true
  mesh_gateway             = true
  register                 = true
  expose_admin             = true
  bind_addresses           = { "default" : "0.0.0.0:8443" }

  env = concat(module.license.license_docker_env, [
    "CONSUL_HTTP_TOKEN=${data.consul_acl_token_secret_id.betaGatewaySecrets[each.key].secret_id}"
  ])
}
