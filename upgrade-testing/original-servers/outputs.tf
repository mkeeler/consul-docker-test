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
  value = docker_network.network
}

output "api" {
  value = "http://localhost:${module.servers.servers[0].ports[0].external}"
}

output "cluster_id" {
  value = module.cluster_id
}

output "containers" {
  value = [
    for srv in module.servers.servers :
    srv.name
  ]
}
