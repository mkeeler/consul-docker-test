output "networks" {
   value = {
      for idx, net in docker_network.networks:
      var.networks[idx] => net
   }
}