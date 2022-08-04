output "enterprise" {
  value = var.enterprise
}

output "join" {
  value = module.servers.join
}

output "consul_image" {
  value = docker_image.consul
}

output "network" {
  value = data.terraform_remote_state.original.outputs.network
}

output "api" {
  value = "http://localhost:${module.servers.servers[0].ports[0].external}"
}

output "cluster_id" {
  value = data.terraform_remote_state.original.outputs.cluster_id
}
