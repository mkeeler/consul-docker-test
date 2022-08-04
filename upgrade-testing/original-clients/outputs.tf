output "containers" {
  value = flatten([
    for partition, outputs in module.clients :
    [for client in outputs.clients : client.name]
  ])
}
