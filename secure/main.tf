provider "docker" {
   version = "2.7.0"
   host = "unix:///var/run/docker.sock"
}

// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length = 4
  special = false
  upper = false
}

locals {
   cluster_id = random_string.cluster_id.result
   ca_key_pem = file(var.tls_ca_key_file)
   ca_cert_pem = file(var.tls_ca_cert_file)
}

resource "docker_network" "consul_network" {
   name = "consul-adoption-day-${local.cluster_id}"
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
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   default_name_include_dc = false
   default_name_suffix = "-${local.cluster_id}"
   enable_healthcheck = true
   
   tls_enabled = true
   tls_ca_cert = local.ca_cert_pem
   tls_ca_key = local.ca_key_pem
   tls_organization = var.tls_organization
   tls_organizational_unit = var.tls_organizational_unit
   tls_country = var.tls_country
   tls_province = var.tls_province
   tls_locality = var.tls_locality
   tls_street_address = var.tls_street_address
   tls_postal_code = var.tls_postal_code

   # 3 servers all with defaults
   servers = [{},{},{}]
}

module "clients" {
   source = "../modules/clients"
   
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.name
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   extra_args = module.servers.join
   
   tls_enabled = true
   tls_ca_cert = local.ca_cert_pem
   tls_ca_key = local.ca_key_pem
   tls_organization = var.tls_organization
   tls_organizational_unit = var.tls_organizational_unit
   tls_country = var.tls_country
   tls_province = var.tls_province
   tls_locality = var.tls_locality
   tls_street_address = var.tls_street_address
   tls_postal_code = var.tls_postal_code
   
   clients = [
      {
         "name": "consul-ui-${local.cluster_id}",
         "extra_args": ["-ui"],
         "ports": {
            "http": {
               "internal": 8501,
               "external": 8501,
               "protocol": "tcp",
            },
            "dns": {
               "internal": 8600,
               "external": 8600,
               "protocol": "udp",
            },
         }
      }
   ]
}