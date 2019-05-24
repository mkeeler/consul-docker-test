output "join" {
  value = formatlist("--retry-join=%s", local.server_hostnames)
}

output "wan_join" {
  value = formatlist("--retry-join-wan=%s", local.server_hostnames)
}
