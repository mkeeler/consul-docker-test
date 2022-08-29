resource "kubernetes_manifest" "peering_token" {
  manifest = {
    apiVersion = "consul.hashicorp.com/v1alpha1"
    kind       = "PeeringAcceptor"

    metadata = {
      name = var.peer_name
      namespace = var.namespace
    }

    spec = {
      peer = {
        secret = {
          name = "${var.peer_name}-peering-token"
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

data "kubernetes_secret" "peering_token" {
  depends_on = [kubernetes_manifest.peering_token]
  metadata {
    name = "${var.peer_name}-peering-token"
    namespace = var.namespace
  }
}