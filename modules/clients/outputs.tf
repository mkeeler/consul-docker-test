output "clients" {
  value = docker_container.client-containers
}

output "hostnames" {
  value = [
    for client in docker_container.client-containers :
    client.hostname
  ]
}
