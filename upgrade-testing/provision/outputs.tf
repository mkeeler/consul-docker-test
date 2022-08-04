output "partitions" {
  value = toset(concat(["default"], !local.enterprise ? [] : [
    for partition, ns in local.partitionsAndNamespaces :
    partition if partition != "default"
  ]))
}
