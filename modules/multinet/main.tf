resource "docker_network" "networks" {
   count = length(var.networks)
   
   name = var.append_cluster_id ? format("%s-%s", var.networks[count.index], var.cluster_id) : var.networks[count.index]
   labels {
      label = "consul.cluster_id"
      value = var.cluster_id
   }
   check_duplicate = "true"
   driver = "bridge"
   options = {
      "com.docker.network.bridge.enable_icc" = "true"
      "com.docker.network.bridge.enable_ip_masquerade" = "true"
   }
   internal = false
}