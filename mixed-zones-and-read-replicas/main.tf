variable "consul_image" {
   type = string
   default = "hashicorp/consul-enterprise"
   description = "The name of the consul docker image to use"
}

resource "docker_image" "consul" {
   name = var.consul_image
   keep_locally = true
}

module "multinet" {
   source = "../modules/multinet"
   networks = ["consul-net"]
}

module "license" {
  source = "../modules/license-env"
}

module "servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [module.multinet.networks["consul-net"].name]
   default_image = docker_image.consul.latest
   default_name_prefix="consul-server-"
   default_name_include_dc=false
   
   env = module.license.license_docker_env

   # 3 servers all with defaults
   servers = [
      {
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone1.hcl")
         }
      },{
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone1.hcl")
         }
      },{
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone2.hcl")
         }
      },{
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone2.hcl")
         }
      },{
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone3.hcl")
         }
      },{
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-zone3.hcl")
         }
      }
   ]
}
 
module "read_replicas" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [module.multinet.networks["consul-net"].name]
   default_image = docker_image.consul.latest
   default_name_prefix="consul-replica-"
   default_name_include_dc = false
   bootstrap=false
   extra_args = module.servers.join

   env = module.license.license_docker_env

   # 3 servers all with defaults
   servers = [
      {
         "config": {
            "agent-conf.hcl": file("${path.module}/agent-conf-read-replica.hcl")
         }
      }
   ]
}

module "clients" {
   source = "../modules/clients"

   persistent_data = false
   datacenter = "primary"
   default_networks = [module.multinet.networks["consul-net"].name]
   default_image = docker_image.consul.name
   extra_args = module.servers.join

   env = module.license.license_docker_env

   clients = [
      {
         "name" : "consul-ui"
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
