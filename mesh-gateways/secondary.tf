
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
         "extra_args": ["-grpc-port=8502"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "socat.hcl" = file("${path.module}/consul-config/socat.hcl")
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
         "extra_args": ["-grpc-port=8502", "-log-level", "DEBUG"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "socat-ext.hcl" = file("${path.module}/consul-config/tcpproxy-secondary.hcl")
         },
         "ports": {
            "socat-external": {
               "internal": 8181,
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

resource "docker_container" "secondary-socat" {
   image = "alpine/socat"
   name = "secondary-socat${local.cluster_id}"
   network_mode = "container:${module.secondary_clients.clients[1].name}"
   command = ["-v", "tcp-l:8181,fork", "exec:\"/bin/cat\""]
}

module "secondary-socat-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "secondary-socat-proxy${local.cluster_id}"
   consul_manager = module.secondary_clients.clients[1].name
   sidecar_for = "socat"
   expose_admin = true
}

resource "docker_container" "secondary-tcpproxy" {
   image = "alpine/socat"
   name = "secondary-tcpproxy${local.cluster_id}"
   network_mode = "container:${module.secondary_clients.clients[2].name}"
   command = ["-v", "tcp-l:8181,fork", "tcp-connect:127.0.0.1:10000"]
}

module "secondary-tcpproxy-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "secondary-tcpproxy-proxy${local.cluster_id}"
   consul_manager = module.secondary_clients.clients[2].name
   sidecar_for = "tcpproxy"
   expose_admin = true
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
}