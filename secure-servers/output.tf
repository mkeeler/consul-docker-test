output "join" {
  value = module.servers.join
}

output "segment_joins" {
  value = module.servers.segment_joins
}

output "server_hostnames" {
  value = module.servers.server_hostnames
}

output "wan_join" {
  value = module.servers.wan_join
}

output "servers" {
  value     = module.servers.servers
  sensitive = true
}

output "cluster_id" {
  value = module.servers.cluster_id
}

output "server_group_hostname" {
  value = module.servers.server_group_hostname
}

output "datacenter" {
  value = var.datacenter
}

resource "local_file" "cacert" {
  filename = "${path.module}/${terraform.workspace}/cacert.pem"
  content  = local.ca.certificate_bundle
}

locals {
  api_port = coalesce([for port in module.servers.servers[0].ports : port.internal == 8501 ? tostring(port.external) : ""]...)
}

resource "local_file" "environment" {
  filename = "${path.module}/${terraform.workspace}/env.sh"
  content  = <<-EOT
  export CONSUL_HTTP_ADDR=https://localhost:${local.api_port}
  export CONSUL_HTTP_TOKEN=${local.bootstrap_token}
  export CONSUL_CACERT=${abspath(path.module)}/${terraform.workspace}/cacert.pem
  EOT
}
