output "join" {
  value = formatlist("--retry-join=%s", [
    for srv in docker_container.server-containers :
    srv.hostname
  ])
}

output "segment_joins" {
  value = {
    for name, segment_config in var.segments :
    name => formatlist("--retry-join=%s", [
      for srv in docker_container.server-containers :
      format("%s:%s", srv.hostname, segment_config["port"])
    ])
  }
}

output "server_hostnames" {
  value = [
    for srv in docker_container.server-containers :
    srv.hostname
  ]
}

output "wan_join" {
  value = formatlist("--retry-join-wan=%s", [
    for srv in docker_container.server-containers :
    srv.hostname
  ])
}

output "servers" {
  value = docker_container.server-containers
}

output "cluster_id" {
  value = random_string.server_group_id.result
}

output "server_group_hostname" {
  value = local.server_group_name
}

output "port" {
  value = docker_container.server-containers[0].ports
}
