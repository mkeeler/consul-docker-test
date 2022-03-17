output "license" {
  value = local.license
}

output "license_docker_env" {
  value = [
    "CONSUL_LICENSE=${local.license}"
  ]
}