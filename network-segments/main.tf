provider "docker" {
   # currently need to build from github.com/mkeeler/terraform-provider-docker
   # and put into ~/.terraform.d/plugins/<platform>/terraform-provider-docker_v2.0.0
   version = "2.0.0"
   host = "unix:///var/run/docker.sock"
}

resource "docker_network" "consul_lan" {
   name = "consul-lan"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_segment_1" {
   name = "consul-segment-1"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_network" "consul_segment_2" {
   name = "consul-segment-2"
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}

resource "docker_image" "consul" {
   name = "consul-dev"
   keep_locally = true
}

module "servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_lan.name, docker_network.consul_segment_1.name, docker_network.consul_segment_2.name]
   default_image = docker_image.consul.name
   default_name_include_dc = false
   segments = {
      "seg1": {
         "bind": "{{ GetInterfaceIP \\\"eth1\\\" }}",
         "port": 8303,
      },
      "seg2": {
         "bind": "{{ GetInterfaceIP \\\"eth2\\\" }}",
         "port": 8304,
      }
   }
   extra_args=["-bind=0.0.0.0",
               "-advertise", "{{ GetInterfaceIP \"eth0\" }}"]
   
   # 3 servers all with defaults
   servers = [{},{},{}]
}

module "lan_clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_lan.name]
   default_image = docker_image.consul.name
   extra_args = module.servers.join
   default_name_include_dc = false

   clients = [
      {
         "name": "consul-ui",
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

module "seg1_clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_segment_1.name]
   default_image = docker_image.consul.name
   extra_args = concat(module.servers.segment_joins["seg1"], ["-segment", "seg1"])
   default_name_include_dc = false
   default_name_prefix = "consul-client-seg1"
   
   clients = [{},{}]
}

module "seg2_clients" {
   source = "../modules/clients"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_segment_2.name]
   default_image = docker_image.consul.name
   extra_args = concat(module.servers.segment_joins["seg2"], ["-segment", "seg2"])
   default_name_include_dc = false
   default_name_prefix = "consul-client-seg2"

   clients = [{},{}]
}