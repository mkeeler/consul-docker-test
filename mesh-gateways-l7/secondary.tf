
module "secondary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "secondary"
   default_config = {
      "agent-conf.hcl" = local.agent_conf
   }
   default_name_prefix = "consul-server${local.cluster_id}-"
   default_networks = [docker_network.consul_secondary_network.name, docker_network.consul_bridge_network.name]
   default_image = docker_image.consul.name
   extra_args =concat(["-bind=0.0.0.0",
                       "-advertise", "{{ GetInterfaceIP \"eth0\" }}",
                       "-advertise-wan", "{{ GetInterfaceIP \"eth1\" }}",
                      ],
                      module.primary_servers.wan_join)


   # 3 servers all with defaults
   servers = [{},{},{}]

   # depends_on = [module.primary_servers]
}

module "secondary_clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "secondary"
   default_config = {
      "agent-conf.hcl" = local.agent_conf
   }
   default_name_prefix = "consul-client${local.cluster_id}-"
   default_networks = [docker_network.consul_secondary_network.name]
   default_image = docker_image.consul.name
   extra_args = module.secondary_servers.join

   clients = [
      {
         "name" : "consul-secondary-ui${local.cluster_id}"
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
      {
         // mostly defaults here - name will be consul-client${local.cluster_id}-primary-1
         // will have an agent with the socat service running along with a sidecar proxy
         // we will need to spawn an envoy image into this name space
         "name": "consul-secondary-api-v2-manager${local.cluster_id}",
         "extra_args": ["-grpc-port=8502"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "api-v2.hcl" = file("${path.module}/consul-config/api-v2.hcl")
         }
         "ports": {
            "envoy-admin": {
               "internal": 19000,
               "external": 19013,
               "protocol": "tcp"
            }
         }
      },
      {
         "name": "consul-secondary-web-manager${local.cluster_id}",
         "extra_args": ["-grpc-port=8502", "-log-level", "DEBUG"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "web.hcl" = file("${path.module}/consul-config/web.hcl")
         },
         "ports": {
            "web-external": {
               "internal": 10000,
               "external": 10002,
               "protocol": "tcp"
            },
            "envoy-admin": {
               "internal": 19000,
               "external": 19012,
               "protocol": "tcp"
            }
         }
      },
      {
         "name": "consul-secondary-gateway-manager${local.cluster_id}",
         "networks": [docker_network.consul_secondary_network.name, docker_network.consul_bridge_network.name],
         "extra_args": [
            "-grpc-port=8502",
            "-log-level", "DEBUG",
            "-bind=0.0.0.0",
            "-advertise", "{{ GetInterfaceIP \"eth0\" }}",
            "-advertise-wan", "{{ GetInterfaceIP \"eth1\" }}",
         ],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            # "mg.hcl" = file("gateway.hcl")
         },
         "ports": {
            "envoy-admin": {
               "internal": 19000,
               "external": 19011,
               "protocol": "tcp"
            }
         }
      }
   ]
}

module "secondary-gateway" {
   source = "../modules/consul-envoy"
   consul_envoy_image = var.consul_envoy_image
   name = "secondary-gateway${local.cluster_id}"
   consul_manager = module.secondary_clients.clients[3].name
   container_network_inject = true
   mesh_gateway = true
   register = true
   expose_admin = true
   bind_addresses = {"default": "0.0.0.0:8443"}
}

resource "docker_container" "secondary-api" {
   image = "nginxdemos/hello"
   name = "secondary-api${local.cluster_id}"
   network_mode = "container:${module.secondary_clients.clients[1].name}"
   command = []
}
module "secondary-api-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "secondary-api-proxy${local.cluster_id}"
   consul_manager = module.secondary_clients.clients[1].name
   sidecar_for = "api"
   expose_admin = true
}

resource "docker_container" "secondary-web" {
   image = "nginxdemos/hello"
   name = "secondary-web${local.cluster_id}"
   network_mode = "container:${module.secondary_clients.clients[2].name}"
   command = []
}
module "secondary-web-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "secondary-web-proxy${local.cluster_id}"
   consul_manager = module.secondary_clients.clients[2].name
   sidecar_for = "web"
   expose_admin = true
}