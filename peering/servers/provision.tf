resource "null_resource" "peering" {
  depends_on = [
    module.clusters,
  ]
  provisioner "local-exec" {
    environment = {
      FOO_TOKEN = random_uuid.management_tokens[0].result
      BAR_TOKEN = random_uuid.management_tokens[1].result
      FOO_API   = "https://localhost:${local.exposedAPIPorts[0]}"
      BAR_API   = "https://localhost:${local.exposedAPIPorts[1]}"
    }
    command = "${path.module}/setup-peering.sh"
  }
}
