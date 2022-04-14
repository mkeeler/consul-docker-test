// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length  = 4
  special = false
  upper   = false
}

locals {
  cluster_id = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""
}

resource "docker_network" "consul_network" {
  name            = "consul-raft-metrics${local.cluster_id}"
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

module "license" {
  source = "../modules/license-env"
}

module "servers" {
  source = "../modules/servers"

  persistent_data         = true
  datacenter              = "primary"
  default_name_include_dc = false
  default_networks        = [docker_network.consul_network.name]
  default_image           = docker_image.consul.latest
  default_name_prefix     = "consul-server-"
  default_name_suffix     = local.cluster_id
  default_config = {
    "agent-conf.hcl" = file("agent-conf.hcl")
  }

  env = module.license.license_docker_env

  # 3 servers all with defaults
  servers = [{}, {}, {}]
}

module "clients" {
  source = "../modules/clients"

  persistent_data         = false
  datacenter              = "primary"
  default_name_include_dc = false
  default_name_prefix     = "consul-client-"
  default_name_suffix     = local.cluster_id
  default_networks        = [docker_network.consul_network.name]
  default_image           = docker_image.consul.latest
  extra_args              = module.servers.join

  default_config = {
    "agent-conf.hcl" = file("agent-conf.hcl")
  }

  env = module.license.license_docker_env

  clients = [
    {
      "name" : "consul-ui${local.cluster_id}"
      "extra_args" : ["-ui"],
      "ports" : {
        "http" : {
          "internal" : 8500,
          "external" : 8500,
          "protocol" : "tcp",
        },
        "dns" : {
          "internal" : 8600,
          "external" : 8600,
          "protocol" : "udp",
        },
      }
    },
  ]
}

locals {
  promcfg = templatefile("${path.module}/prometheus/prometheus.yml", { "cluster_id" : local.cluster_id, "consulServers" : module.servers.server_hostnames, "consulClients" : module.clients.hostnames })
}

module "prometheus" {
  source = "../modules/prometheus"

  unique_id = local.cluster_id
  networks  = [docker_network.consul_network.name]
  config    = local.promcfg
}

module "grafana" {
  source = "../modules/grafana"

  unique_id = local.cluster_id
  provisioning = [
    {
      type    = "datasource"
      name    = "datasource.yaml"
      content = templatefile("${path.module}/grafana/prometheus-data-source.yaml", { "prometheus_address" : "${module.prometheus.container.name}:9090" })
    },
    {
      type    = "dashboard"
      name    = "dashboards.yml"
      content = file("${path.module}/grafana/dashboards.yml")
    },
    {
      type    = "dashboard"
      name    = "raft-performance.json"
      content = file("${path.module}/grafana/raft-performance.json")
    },
    {
      type    = "dashboard"
      name    = "performance.json"
      content = file("${path.module}/grafana/performance.json")
    },
  ]
  networks = [docker_network.consul_network.name]
}

output "urls" {
  value = {
    "consul" : "http://localhost:8500",
    "prometheus" : "http://localhost:9090",
    "grafana" : "http://localhost:3000"
  }
}

output "containers" {
  value = {
    for container in concat(module.servers.servers, module.clients.clients, [module.prometheus.container, module.grafana.container]) :
    container.id => container.name
  }
}

