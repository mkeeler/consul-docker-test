resource "docker_network" "consul_network" {
   name = "consul-raft-perf"
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
   default = "consul:latest"
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
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.latest
   default_name_prefix="consul-server-"
   default_name_include_dc=false
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   
   env = module.license.license_docker_env

   # 3 servers all with defaults
   servers = [{
      "ports": {
         "http": {
            "internal": 8500,
            "external": 8500,
            "protocol": "tcp",
         },
         "grpc": {
            "internal": 8502,
            "external": 8502,
            "protocol": "tcp",
         }
      }
   },{},{}]
}
