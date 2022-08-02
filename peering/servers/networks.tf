resource "docker_network" "network" {
  name            = "consul${local.cluster_id_suffix}"
  check_duplicate = "true"
  driver          = "bridge"
  options = {
    "com.docker.network.bridge.enable_icc"           = "true"
    "com.docker.network.bridge.enable_ip_masquerade" = "true"
  }
  internal = false
}
