// some randomness so we can create two of these clusters at once if necessary
resource "random_string" "cluster_id" {
  length = 4
  special = false
  upper = false
}

locals {
   cluster_id = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""
   ca_key_pem = file(var.tls_ca_key_file)
   ca_cert_pem = file(var.tls_ca_cert_file)
}

resource "docker_network" "consul_network" {
   name = "consul${local.cluster_id}"
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

module "license" {
  source = "../modules/license-env"
}

module "servers" {
   source = "../modules/servers"

   persistent_data = true
   datacenter = "primary"
   default_networks = [docker_network.consul_network.name]
   default_image = docker_image.consul.latest
   default_name_prefix="consul-server${local.cluster_id}-"
   default_name_include_dc=false
   default_config = {
      "agent-conf.hcl" = file("agent-conf.hcl")
   }
   
   env = module.license.license_docker_env
   
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
   servers = [{
      "ports": {
         "http": {
            "internal": 8500,
            "external": 8500,
            "protocol": "tcp",
         },
         "https": {
            "internal": 8501,
            "external": 8501,
            "protocol": "tcp",
         }
         "grpc": {
            "internal": 8502,
            "external": 8502,
            "protocol": "tcp",
         }
      }
   },{},{}]
}

module "monitoring" {
   source = "../modules/monitoring"
   
   networks = [docker_network.consul_network.name]
   
   prometheus_port_mapping = 9090
   
   prometheus_jobs = [
      {
         "name": "consul-servers",
         "path": "/v1/agent/metrics",
         "params": {
            "format": "prometheus"
         },
         # this is the agent master token from agent-conf.hcl
         "bearer_token": "448eada4-df07-4633-8a17-d0ba7147cde4",
         "use_tls": true,
         "targets": [
            for name in module.servers.server_hostnames:
            "${name}:8500"
         ],
         
      }
   ]
}
