output "join" {
  value = formatlist("--retry-join=%s", [
    for srv in docker_container.server-containers:
    srv.hostname
  ])
}

output "wan_join" {
  value = formatlist("--retry-join-wan=%s", [
    for srv in docker_container.server-containers:
    srv.hostname
  ])
}

output "servers" {
  value = docker_container.server-containers
}
