provider "docker" {
   # currently need to build from github.com/mkeeler/terraform-provider-docker
   # and put into ~/.terraform.d/plugins/<platform>/terraform-provider-docker_v2.0.0
   version = "2.0.0"
   host = "unix:///var/run/docker.sock"
}

resource "docker_network" "consul_network" {
   name = "consul-simple-net"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_image" "consul" {
   name = "consul:latest"
   keep_locally = true
}

module "primary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   default_name_prefix="consul-simple-server-"

   # 3 servers all with defaults
   servers = [{},{},{}]
}

module "primary_clients" {
   source = "../modules/clients"

   persistent_data = false
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   extra_args = module.primary_servers.join

   clients = [
      {
         "name" : "consul-simple-ui"
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