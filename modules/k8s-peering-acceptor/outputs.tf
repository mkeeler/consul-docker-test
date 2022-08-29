output "peering_token" {
   sensitive = true
   value = data.kubernetes_secret.peering_token.data["peering-token"]
}