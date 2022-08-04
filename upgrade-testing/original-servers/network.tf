resource "docker_network" "network" {
  name            = "consul${module.cluster_id.name_suffix}"
  check_duplicate = "true"
  driver          = "bridge"
  options = {
    "com.docker.network.bridge.enable_icc"           = "true"
    "com.docker.network.bridge.enable_ip_masquerade" = "true"
  }
  internal = false
}
