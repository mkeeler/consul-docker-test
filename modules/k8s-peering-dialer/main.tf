resource "kubernetes_secret" "peering_token" {
  metadata {
    name      = "consul-${var.peer_name}-peering-token"
    namespace = var.namespace
  }

  data = {
    "peering-token" = var.peering_token
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "peering_token" {
  depends_on = [kubernetes_secret.peering_token]
  manifest = {
    apiVersion = "consul.hashicorp.com/v1alpha1"
    kind       = "PeeringDialer"

    metadata = {
      name = var.peer_name
      namespace = var.namespace
    }

    spec = {
      peer = {
        secret = {
          name = "consul-${var.peer_name}-peering-token"
          key = "peering-token"
          backend = "kubernetes"
        }
      }
    }
  }
  
  wait {
    fields = {
      "status.conditions[0].status" = "True",
    }
  }
}
