// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length = 4
  special = false
  upper = false
}

locals {
   cluster_id = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""

   agent_conf = file("${path.module}/consul-config/agent-conf.hcl")
   client_conf = file("${path.module}/consul-config/client.hcl")
}

resource "docker_network" "consul_network" {
   name = "consul-net${local.cluster_id}"
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

module "servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_config = {
      "agent-conf.hcl" = local.agent_conf
   }
   default_name_prefix = "consul-server${local.cluster_id}-"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   extra_args=["-bind=0.0.0.0","-advertise", "{{ GetInterfaceIP \"eth0\" }}"]

   # 3 servers all with defaults
   servers = [{},{},{}]
}


module "clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "primary"
   default_config = {
      "agent-conf.hcl" = local.agent_conf
      "client.hcl" = local.client_conf
   }
   default_name_prefix = "consul-client${local.cluster_id}-"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   extra_args = module.servers.join

   clients = [
      {
         "name" : "consul-ui${local.cluster_id}"
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
      {
         // mostly defaults here - name will be consul-client${local.cluster_id}-primary-1
         // will have an agent with the socat service running along with a sidecar proxy
         // we will need to spawn an envoy image into this name space
         "extra_args": ["-grpc-port=8502"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "web.hcl" = file("${path.module}/consul-config/web.hcl")
         },
         "ports": {
            "envoy-admin": {
               "internal": 19000,
               "external": 19001,
               "protocol": "tcp"
            },
            "web-external": {
               "internal": 8080,
               "external": 10001,
               "protocol": "tcp"
            }
         }
      },
      {
         "extra_args": ["-grpc-port=8502"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "api.hcl" = file("${path.module}/consul-config/api.hcl")
         },
         "ports": {
            "envoy-admin": {
               "internal": 19000,
               "external": 19002,
               "protocol": "tcp"
            },
         }
      },
      {
         "extra_args": ["-grpc-port=8502"],
         "config": {
            "agent-conf.hcl" = local.agent_conf
            "api.hcl" = file("${path.module}/consul-config/api.hcl")
         },
         "ports": {
            "envoy-admin": {
               "internal": 19000,
               "external": 19003,
               "protocol": "tcp"
            },
         }
      },
   ]
}

resource "docker_container" "web" {
   image = "alpine/socat"
   name = "web${local.cluster_id}"
   network_mode = "container:${module.clients.clients[1].name}"
   command = ["-v", "tcp-l:8080,fork", "tcp-connect:127.0.0.1:10000"]
}

module "web-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "web-proxy${local.cluster_id}"
   consul_manager = module.clients.clients[1].name
   sidecar_for = "web"
   expose_admin = true
}

resource "docker_container" "api1" {
   image = "hashicorp/http-echo"
   name = "api1${local.cluster_id}"
   network_mode = "container:${module.clients.clients[2].name}"
   command = ["-listen=:8080", "-text=\"api - instance 1\""]
}

module "api1-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "api1-proxy${local.cluster_id}"
   consul_manager = module.clients.clients[2].name
   sidecar_for = "api"
   expose_admin = true
}

resource "docker_container" "api2" {
   image = "hashicorp/http-echo"
   name = "api2${local.cluster_id}"
   network_mode = "container:${module.clients.clients[3].name}"
   command = ["-listen=:8080", "-text=\"api - instance 2\""]
}

module "api2-proxy" {
   source = "../modules/consul-envoy"

   consul_envoy_image = var.consul_envoy_image
   name = "api2-proxy${local.cluster_id}"
   consul_manager = module.clients.clients[3].name
   sidecar_for = "api"
   expose_admin = true
}