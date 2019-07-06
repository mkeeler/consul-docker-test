provider "docker" {
   version = "2.0.0"
   host = "unix:///var/run/docker.sock"
}


// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length = 4
  special = false
  upper = false
}

locals {
   cluster_id = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""

   agent_conf = file("${path.module}/consul-config/agent-conf.hcl")
}

resource "docker_network" "consul_bridge_network" {
   name = "consul-wan-net${local.cluster_id}"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_primary_network" {
   name = "consul-primary-net${local.cluster_id}"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_secondary_network" {
   name = "consul-secondary-net${local.cluster_id}"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_image" "consul" {
   name = var.consul_image
   keep_locally = true
}

module "prometheus" {
   source = "../modules/prometheus"

   unique_id = var.use_cluster_id ? random_string.cluster_id.result : ""
   networks = [
      docker_network.consul_bridge_network.name,
      docker_network.consul_primary_network.name,
      docker_network.consul_secondary_network.name
   ]

   config = templatefile("${path.module}/prometheus/prometheus.yml", {"cluster_id": local.cluster_id})
}

module "grafana" {
   source = "../modules/grafana"

   unique_id = var.use_cluster_id ? random_string.cluster_id.result : ""
   provisioning = [
      {
         type = "datasource"
         name = "datasource.yaml"
         content =  templatefile("${path.module}/grafana/prometheus-data-source.yaml", {"prometheus_address": "prometheus${local.cluster_id}:9090"})
      },
      {
         type = "dashboard"
         name = "dashboards.yml"
         content = file("${path.module}/grafana/dashboards.yml")
      },
      {
         type = "dashboard"
         name = "raft-performance.json"
         content = file("${path.module}/grafana/raft-performance.json")
      }
   ]
   networks = [docker_network.consul_bridge_network.name]
}
