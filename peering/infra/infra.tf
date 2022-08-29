locals {
  default_image_version = var.consul_version == "local" ? "local" : var.enterprise ? "${var.consul_version}-ent" : var.consul_version
  default_image_source  = var.enterprise ? "hashicorp/consul-enterprise" : "hashicorp/consul"
  default_image         = var.consul_image != "" ? var.consul_image : "${local.default_image_source}:${local.default_image_version}"
}

// find the consul image to use
resource "docker_image" "consul" {
  name         = local.default_image
  keep_locally = true
}

resource "docker_image" "k3d" {
  name         = "rancher/k3s:v1.23.9-k3s1"
  keep_locally = true
}

// initialize a cluster id
module "cluster_id" {
  source                       = "../../modules/cluster-id"
  resources_include_cluster_id = var.use_cluster_id
}

// Import the enterprise license from the environment
module "license" {
  source = "../../modules/license-env"
}

// Docker Network for all clusters to share
resource "docker_network" "network" {
  name            = "consul-peering${module.cluster_id.name_suffix}"
  check_duplicate = "true"
  driver          = "bridge"
  options = {
    "com.docker.network.bridge.enable_icc"           = "true"
    "com.docker.network.bridge.enable_ip_masquerade" = "true"
  }
  internal = false

  dynamic "labels" {
    for_each = module.cluster_id.resource_labels
    content {
      label = labels.key
      value = labels.value
    }
  }
}

// Create a K8s cluster using K3d (K3s utilizing docker-in-docker)
// The gamma k3d cluster is intended to have Consul servers and clients
// all within the default partition.
resource "k3d_cluster" "gamma" {
  name    = "gamma${module.cluster_id.name_suffix}"
  servers = 1
  agents  = var.high_availability ? 2 : 0
  image   = docker_image.k3d.name
  network = docker_network.network.name
}

// Create a K8s cluster using K3d (K3s utilizing docker-in-docker)
// The delta k3d cluster is intended to have only consul clients
// within some non-default partition. Therefore we only provision
// the cluster if enterprise is enabled.
resource "k3d_cluster" "delta" {
  count   = var.enterprise ? 1 : 0
  name    = "delta${module.cluster_id.name_suffix}"
  servers = 1
  agents  = var.high_availability ? 2 : 0
  image   = docker_image.k3d.name
  network = docker_network.network.name

  k8s_api_host_port = 6551
}

// Create the certificate authorities to sign Consul certificates
module "certificate_authority" {
  source      = "../../modules/tls_ca"
  days        = 30
  common_name = "Consul Peering Root CA ${module.cluster_id.id}"
}
