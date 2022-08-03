resource "null_resource" "peering" {
  count = var.disable_provisioning ? 0 : 1
  depends_on = [
    module.clusters,
  ]
  provisioner "local-exec" {
    environment = {
      ALPHA_TOKEN = random_uuid.management_tokens[0].result
      BETA_TOKEN  = random_uuid.management_tokens[1].result
      ALPHA_API   = "https://localhost:${local.exposedAPIPorts[0]}"
      BETA_API    = "https://localhost:${local.exposedAPIPorts[1]}"
      ENTERPRISE  = var.enterprise ? "true" : "false"
    }
    command = "${path.module}/setup-peering.sh"
  }
}
