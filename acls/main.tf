resource "docker_network" "consul_primary_network" {
   name = "consul-primary-net"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_secondary_network" {
   name = "consul-secondary-net"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_bridge_network" {
   name = "consul-wan-net"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

variable "consul_image" {
   type = string
   default = "consul-dev"
   description = "Name of the Consul container image to use"
}

resource "docker_image" "consul" {
   name = var.consul_image
   keep_locally = true
}

module "license" {
   source = "../modules/license-env"
}

module "primary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   default_networks = [docker_network.consul_primary_network.name, docker_network.consul_bridge_network.name]
   default_image = docker_image.consul.latest
   extra_args=["-bind=0.0.0.0",
               "-advertise", "{{ GetInterfaceIP \"eth0\" }}",
               "-advertise-wan", "{{ GetInterfaceIP \"eth1\" }}",
              ]

   env = [
      "CONSUL_LICENSE=${module.license.license}"
   ]

   # 3 servers all with defaults
   servers = [{},{},{}]
}

module "primary_clients" {
   source = "../modules/clients"

   persistent_data = false
   datacenter = "primary"
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   default_networks = [docker_network.consul_primary_network.name]
   default_image = docker_image.consul.latest
   extra_args = module.primary_servers.join

   clients = [
      {
         "name" : "consul-primary-ui"
         "extra_args": ["-ui"],
         "ports": {
            "http": {
               "internal": 8500,
               "external": 8500,
               "protocol": "tcp",
            },
            "dns": {
               "internal": 8600,
               "external": 8600,
               "protocol": "udp",
            },
         }
      },
   ]
}

module "secondary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "secondary"
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   default_networks = [docker_network.consul_secondary_network.name, docker_network.consul_bridge_network.name]
   default_image = docker_image.consul.latest
   extra_args =concat(["-bind=0.0.0.0",
                       "-advertise", "{{ GetInterfaceIP \"eth0\" }}",
                       "-advertise-wan", "{{ GetInterfaceIP \"eth1\" }}",
                      ], 
                      module.primary_servers.wan_join)

   env = [
      "CONSUL_LICENSE=${module.license.license}"
   ]
   
   # 3 servers all with defaults
   servers = [{},{},{}]
}

module "secondary_clients" {
   source = "../modules/clients"

   persistent_data = false
   datacenter = "secondary"
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   default_networks = [docker_network.consul_secondary_network.name]
   default_image = docker_image.consul.latest
   extra_args = module.secondary_servers.join

   env = [
      "CONSUL_LICENSE=${module.license.license}"
   ]
   
   clients = [
      {
         "name" : "consul-secondary-ui"
         "extra_args": ["-ui"],
         "ports": {
            "http": {
               "internal": 8500,
               "external": 8501,
               "protocol": "tcp",
            },
            "dns": {
               "internal": 8600,
               "external": 8601,
               "protocol": "udp",
            },
         }
      },
   ]
}

module "prometheus" {
   source = "../modules/prometheus"

   unique_id = ""
   networks = [
      docker_network.consul_bridge_network.name,
      docker_network.consul_primary_network.name,
      docker_network.consul_secondary_network.name
   ]

   config = templatefile("${path.module}/prometheus/prometheus.yml", {"cluster_id": ""})
}

module "grafana" {
   source = "../modules/grafana"

   unique_id = ""
   provisioning = [
      {
         type = "datasource"
         name = "datasource.yaml"
         content =  templatefile("${path.module}/grafana/prometheus-data-source.yaml", {"prometheus_address": "prometheus:9090"})
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
      },
      {
         type = "dashboard"
         name = "replication.json"
         content = file("${path.module}/grafana/replication.json")
      }
   ]
   networks = [docker_network.consul_bridge_network.name]
}
