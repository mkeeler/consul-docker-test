module "multinet" {
   source = "../modules/multinet"
   networks = ["consul-net"]
}

variable "consul_image" {
   type = string
   default = "consul-dev"
   description = "The name of the consul docker image to use"
}

resource "docker_image" "consul" {
   name = var.consul_image
   keep_locally = true
}

module "primary_servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [module.multinet.networks["consul-net"].name]
   default_image = docker_image.consul.name
   default_name_prefix="consul-server-"

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

// module "primary_non_voters" {
//    source = "../modules/servers"
   
//    persistent_data = true
//    datacenter = "primary"
//    default_networks = [docker_network.consul_network.name]
//    extra_args = concat(["-non-voting-server"], module.primary_servers.join)
//    default_image = docker_image.consul.name
//    default_name_prefix="consul-server-nonvoter-"

//    # 3 servers all with defaults
//    servers = [{},{}]
// }

module "primary_clients" {
   source = "../modules/clients"

   persistent_data = false
   datacenter = "primary"
   default_networks = [module.multinet.networks["consul-net"].name]
   default_image = docker_image.consul.name
   extra_args = module.primary_servers.join

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
