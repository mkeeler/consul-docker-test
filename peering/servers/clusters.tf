locals {
  clusterNames    = ["alpha", "beta"]
  exposedAPIPorts = [8501, 9501]

  k8s_clusters = local.enterprise ? ["gamma", "delta"] : ["gamma"]
}

resource "random_id" "gossip_keys" {
  count       = 3
  byte_length = 32
}

resource "random_uuid" "management_tokens" {
  count = 3
}

resource "random_uuid" "recovery_tokens" {
  count = 3
}

module "certificate_authorities" {
  count  = 2
  source = "../../modules/tls_ca"

  days        = 30
  common_name = "Consul Intermediate CA ${local.clusterNames[count.index]} ${local.cluster_id.id}"
  root_ca     = local.ca
}

module "clusters" {
  count  = 2
  source = "../../modules/servers"

  persistent_data         = true
  datacenter              = "primary"
  default_networks        = [local.network.name]
  default_image           = local.consul_image.latest
  default_name_prefix     = "consul-${local.clusterNames[count.index]}-server-"
  default_name_suffix     = local.cluster_id.name_suffix
  default_name_include_dc = false
  default_config = {
    "ports.hcl"        = file("consul-configs/ports.hcl")
    "tls.hcl"          = file("consul-configs/tls.hcl")
    "connect.hcl"      = file("consul-configs/connect.hcl")
    "gossip.hcl"       = templatefile("consul-configs/gossip.hcl", { "gossip_key" : random_id.gossip_keys[count.index].b64_std })
    "acl.hcl"          = templatefile("consul-configs/acl.hcl", { "management" : random_uuid.management_tokens[count.index].result, "recovery" : random_uuid.recovery_tokens[count.index].result })
    "peering.hcl"      = file("consul-configs/peering.hcl")
    "auto-encrypt.hcl" = file("consul-configs/auto-encrypt.hcl")
  }

  env = local.license.license_docker_env

  tls_enabled    = true
  tls_ca_cert    = module.certificate_authorities[count.index].certificate_pem
  tls_ca_key     = module.certificate_authorities[count.index].private_key_pem
  use_tls_stanza = true

  labels = merge(local.cluster_id.resource_labels, {
    "consul" : "server",
    "consul_cluster_name" : local.clusterNames[count.index],
  })

  servers = [
    for i in range(local.high_availability ? 3 : 1) :
    {
      "extra_args" : ["-ui"],
      "ports" : {
        "http" : {
          "internal" : 8501,
          "protocol" : "tcp",
        }
      }
    }
  ]
}

locals {
  gamma_common_values = {
    "server.exposeGossipAndRPCPorts" : "true",
    "server.replicas" : local.high_availability ? "3" : "1",
  }

  gamma_enterprise_values = {
    "global.adminPartitions.service.nodePort.serf" : "32100",
    "global.adminPartitions.service.nodePort.rpc" : "32101",
    "global.adminPartitions.service.nodePort.https" : "32102",
  }

  gamma_values = local.enterprise ? merge(local.gamma_common_values, local.gamma_enterprise_values) : local.gamma_common_values
}

module "k8s_gamma" {
  source = "../../modules/k8s"
  providers = {
    kubernetes = kubernetes.gamma
    helm       = helm.gamma
  }

  name       = "gamma"
  enable_tls = true
  ca    = local.ca
  license    = local.license.license
  enterprise = local.enterprise
  image      = local.consul_image.name

  values = local.gamma_values
}

data "k3d_nodes" "gamma" {
  cluster_name = "gamma"
}

locals {
  serverPods = local.high_availability ? toset(["consul-gamma-server-0", "consul-gamma-server-1", "consul-gamma-server-2"]) : toset(["consul-gamma-server-0"])
}

data "kubernetes_pod" "gamma_servers" {
  for_each = local.serverPods

  depends_on = [module.k8s_gamma]
  provider   = kubernetes.gamma

  metadata {
    name      = each.value
    namespace = "consul"
  }
}

data "kubernetes_secret" "gamma_token" {
  depends_on = [module.k8s_gamma]
  provider = kubernetes.gamma
  metadata {
    name = "consul-gamma-bootstrap-acl-token"
    namespace = "consul"
  }
}

locals {
  serverIPs = [
    for srv in data.kubernetes_pod.gamma_servers :
    data.k3d_nodes.gamma.nodes[coalesce([for spec in srv.spec: spec.node_name]...)].ip
  ]
  
  authMethodHost = coalesce([
    for node in data.k3d_nodes.gamma.nodes:
      lookup(node.runtime_labels, "k3d.cluster.url", "")
  ]...)

  delta_values = {
    "client.exposeGossipPorts" : "true",
    "externalServers.enabled" : "true",
    "externalServers.k8sAuthMethodHost" : "https://k3d-delta-serverlb:6443",
    "global.adminPartitions.name": "baz",
    "server.enabled": "false",
    "global.tls.enableAutoEncrypt": "false",
  }
  
  delta_yaml_values = [
    yamlencode({
      "client": {
        "join": local.serverIPs
      },
      "externalServers": {
        "hosts": local.serverIPs
      }
    }),
  ]
}

module "k8s_delta" {
  count = local.enterprise ? 1 : 0
  source = "../../modules/k8s"
  providers = {
    kubernetes = kubernetes.delta
    helm       = helm.delta
  }

  name       = "delta"
  enable_tls = true
  ca    = module.k8s_gamma.ca
  generate_intermediate_ca = false
  license    = local.license.license
  enterprise = local.enterprise
  image      = local.consul_image.name
  gossip_key = module.k8s_gamma.gossip_key
  bootstrap_token = data.kubernetes_secret.gamma_token.data.token

  values = local.delta_values
  yaml_values = local.delta_yaml_values
}




