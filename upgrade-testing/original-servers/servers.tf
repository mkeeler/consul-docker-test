locals {
  default_image = var.consul_image != "" ? var.consul_image : var.enterprise ? "hashicorp/consul-enterprise:local" : "consul:local"
}

resource "docker_image" "consul" {
  name         = local.default_image
  keep_locally = true
}

module "cluster_id" {
  source                       = "../../modules/cluster-id"
  resources_include_cluster_id = var.use_cluster_id
}

module "license" {
  source = "../../modules/license-env"
}

module "servers" {
  source = "../../modules/servers"

  persistent_data         = false
  datacenter              = "primary"
  default_networks        = [docker_network.network.name]
  default_image           = docker_image.consul.latest
  default_name_prefix     = "consul-server-original-"
  default_name_suffix     = module.cluster_id.name_suffix
  default_name_include_dc = false
  default_config = {
    "connect.hcl"   = file("../consul-configs/connect.hcl")
    "autopilot.hcl" = file("../consul-configs/autopilot.hcl")
    "logging.hcl"   = file("../consul-configs/logging.hcl")
  }

  env = module.license.license_docker_env

  labels = module.cluster_id.resource_labels

  servers = [{
    "extra_args" : ["-ui"],
    "ports" : {
      "http" : {
        "internal" : 8500,
        "protocol" : "tcp"
      }
    }
  }, {}, {}]
}
