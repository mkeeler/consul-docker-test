module "cluster_id" {
  source = "../modules/cluster-id"

  resources_include_cluster_id = var.use_cluster_id
}

module "certificate_authority" {
  source = "../modules/tls_ca"
}

module "license" {
  source = "../modules/license-env"
}

resource "docker_network" "consul" {
  name            = "${var.network_name}${module.cluster_id.name_suffix}"
  check_duplicate = "true"
  driver          = "bridge"
  options = {
    "com.docker.network.bridge.enable_icc"           = "true"
    "com.docker.network.bridge.enable_ip_masquerade" = "true"
  }
  internal = false
}

resource "docker_image" "consul" {
  name         = var.consul_image
  keep_locally = true
}

resource "docker_image" "envoy" {
  name         = var.consul_envoy_image
  keep_locally = true
}

resource "random_uuid" "bootstrap_token" {}

resource "random_uuid" "recovery_token" {}

resource "random_id" "gossip_key" {
  byte_length = 32
}

