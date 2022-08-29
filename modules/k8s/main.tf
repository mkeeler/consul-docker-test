locals {
  default_image_version = var.consul_version == "local" ? "local" : var.enterprise ? "${var.consul_version}-ent" : var.consul_version
  default_image_source  = var.enterprise ? "hashicorp/consul-enterprise" : "hashicorp/consul"
  consul_image          = var.image != "" ? var.image : "${local.default_image_source}:${local.default_image_version}"
}

resource "random_id" "gossip_key" {
  byte_length = 32
}

locals {
  gossip_key = var.gossip_key != "" ? var.gossip_key : random_id.gossip_key.b64_std
  tlsCount   = var.enable_tls ? 1 : 0
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

module "cluster_ca" {
  count  = var.generate_intermediate_ca ? local.tlsCount : 0
  source = "../tls_ca"

  days        = 30
  common_name = "Consul K8s Intermediate CA ${var.name}"
  root_ca     = var.ca
}

locals {
  cluster_ca = var.generate_intermediate_ca ? module.cluster_ca[0] : var.ca
}

resource "kubernetes_secret" "gossip_key" {
  metadata {
    namespace = kubernetes_namespace.consul.metadata[0].name
    name      = "consul-gossip-key"
  }

  data = {
    key = local.gossip_key
  }

  type = "Opaque"
}

resource "kubernetes_secret" "caCert" {
  count = local.tlsCount

  metadata {
    namespace = kubernetes_namespace.consul.metadata[0].name
    name      = "consul-ca-cert"
  }

  data = {
    "tls.cert" = local.cluster_ca.certificate_bundle
  }

  type = "Opaque"
}

resource "kubernetes_secret" "caKey" {
  count = local.tlsCount

  depends_on = [kubernetes_namespace.consul]
  metadata {
    namespace = kubernetes_namespace.consul.metadata[0].name
    name      = "consul-ca-key"
  }

  data = {
    "tls.key" = local.cluster_ca.private_key_pem
  }

  type = "Opaque"
}

resource "kubernetes_secret" "license" {
  count = var.license != "" ? 1 : 0

  depends_on = [kubernetes_namespace.consul]
  metadata {
    name      = "consul-license"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    "license" = var.license
  }

  type = "Opaque"
}

resource "kubernetes_secret" "bootstrap_token" {
  depends_on = [kubernetes_namespace.consul]
  metadata {
    name      = "consul-delta-cluster-token"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  data = {
    "token" = var.bootstrap_token
  }

  type = "Opaque"
}

locals {
  tlsValues = {
    "global.tls.enabled" : "true"
    "global.tls.httpsOnly" : "true",
    "global.tls.caCert.secretName" : "consul-ca-cert",
    "global.tls.caCert.secretKey" : "tls.cert",
    "global.tls.caKey.secretName" : "consul-ca-key",
    "global.tls.caKey.secretKey" : "tls.key",
  }
  
  bootstrapTokenValues = {
    "global.acls.bootstrapToken.secretName": "consul-delta-cluster-token",
    "global.acls.bootstrapToken.secretKey": "token",
  }

  commonValues = {
    "global.name" : "consul-${var.name}",
    "connectInject.enabled" : "true",
    "controller.enabled" : "true",
    "global.peering.enabled" : "true",
    "global.image" : local.consul_image,
    "global.gossipEncryption.secretName" : "consul-gossip-key",
    "global.gossipEncryption.secretKey" : "key",
    "global.acls.manageSystemACLs" : "true",
    "global.metrics.enabled" : "true",
    "global.metrics.enableAgentMetrics" : "true",
    "meshGateway.enabled" : "true",
    "meshGateway.replicas" : "1",
    "meshGateway.service.type" : "NodePort",
    "meshGateway.service.nodePort" : "30100",
    "server.exposeService.type" : "NodePort",
    "server.exposeService.nodePort.grpc" : "30200",
  }

  enterpriseValues = {
    "global.adminPartitions.enabled" : "true",
    "global.adminPartitions.service.type" : "NodePort",
    "global.enableConsulNamespaces" : "true",
    "global.enterpriseLicense.secretName" : "consul-license",
    "global.enterpriseLicense.secretKey" : "license"
  }

  helmValues = merge(
    local.commonValues,
    var.enable_tls ? local.tlsValues : {},
    var.enterprise ? local.enterpriseValues : {},
    var.bootstrap_token != "" ? local.bootstrapTokenValues : {},
    var.values,
  )
}

# Install a cluster into Kubernetes
resource "helm_release" "consul" {
  depends_on = [
    kubernetes_secret.gossip_key,
    kubernetes_secret.caCert,
    kubernetes_secret.caKey,
    kubernetes_secret.license,
    kubernetes_secret.bootstrap_token,
  ]

  name       = var.name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "0.47.1"

  namespace        = kubernetes_namespace.consul.metadata[0].name
  create_namespace = false
  
  values = var.yaml_values

  dynamic "set" {
    for_each = local.helmValues
    content {
      name  = set.key
      value = set.value
    }
  }
}
