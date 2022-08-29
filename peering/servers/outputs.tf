locals {
  alpha_host_api_port = module.clusters[0].servers[0].ports[0].external
  beta_host_api_port  = module.clusters[1].servers[0].ports[0].external
}

output "helm_release" {
  sensitive = true
  value     = module.k8s_gamma.helm_release
}

output "license" {
  value = local.license
}

output "enterprise" {
  value = local.enterprise
}

output "consul_image" {
  value = local.consul_image
}

output "cluster_id" {
  value = local.cluster_id
}

output "network" {
  value = local.network
}

output "high_availability" {
  value = local.high_availability
}

output "gamma_k8s_context" {
  value = local.gamma_k8s_context
}

output "delta_k8s_context" {
  value = local.delta_k8s_context
}

output "alpha_api" {
  value = "https://localhost:${local.alpha_host_api_port}"
}

output "beta_api" {
  value = "https://localhost:${local.beta_host_api_port}"
}

output "alpha_ca_cert" {
  value = module.certificate_authorities[0].certificate_pem
}

output "beta_ca_cert" {
  value = module.certificate_authorities[1].certificate_pem
}

output "alpha_ca_key" {
  sensitive = true
  value     = module.certificate_authorities[0].private_key_pem
}

output "beta_ca_key" {
  sensitive = true
  value     = module.certificate_authorities[1].private_key_pem
}

output "alpha_token" {
  sensitive = true
  value     = random_uuid.management_tokens[0].result
}

output "beta_token" {
  sensitive = true
  value     = random_uuid.management_tokens[1].result
}

output "gamma_token" {
  sensitive = true
  value = data.kubernetes_secret.gamma_token.data.token
}

output "delta_token" {
  sensitive = true
  value = data.kubernetes_secret.gamma_token.data.token
}

output "alpha_recovery_token" {
  sensitive = true
  value     = random_uuid.recovery_tokens[0].result
}

output "beta_recovery_token" {
  sensitive = true
  value     = random_uuid.recovery_tokens[1].result
}

output "alpha_join" {
  value = module.clusters[0].join
}

output "beta_join" {
  value = module.clusters[1].join
}

output "alpha_gossip_key" {
  sensitive = true
  value     = random_id.gossip_keys[0].b64_std
}

output "beta_gossip_key" {
  sensitive = true
  value     = random_id.gossip_keys[1].b64_std
}

output "alpha_hostnames" {
  value = module.clusters[0].server_hostnames
}

output "beta_hostnames" {
  value = module.clusters[1].server_hostnames
}

output "alpha" {
  sensitive = true
  value = {
    "tokens" : {
      "management" : random_uuid.management_tokens[0].result,
      "recovery" : random_uuid.recovery_tokens[0].result
    },
    "ca" : {
      "key" : module.certificate_authorities[0].private_key_pem,
      "cert" : module.certificate_authorities[0].certificate_pem
    },
    "gossip_key" : random_id.gossip_keys[0].b64_std,
    "join" : module.clusters[0].join,
    "hostnames" : module.clusters[0].server_hostnames,
    "api" : "https://localhost:${local.alpha_host_api_port}"
  }
}

output "beta" {
  sensitive = true
  value = {
    "tokens" : {
      "management" : random_uuid.management_tokens[1].result,
      "recovery" : random_uuid.recovery_tokens[1].result
    },
    "ca" : {
      "key" : module.certificate_authorities[1].private_key_pem,
      "cert" : module.certificate_authorities[1].certificate_pem
    },
    "gossip_key" : random_id.gossip_keys[1].b64_std,
    "join" : module.clusters[1].join,
    "hostnames" : module.clusters[1].server_hostnames,
    "api" : "https://localhost:${local.beta_host_api_port}"
  }
}

output "alpha_env" {
  value = "${path.module}/alpha/env.sh"
}

output "beta_env" {
  value = "${path.module}/beta/env.sh"
}

resource "local_file" "alphaEnvironment" {
  filename = "${path.module}/alpha/env.sh"
  content  = <<-EOT
  export CONSUL_HTTP_ADDR=https://localhost:${local.alpha_host_api_port}
  export CONSUL_HTTP_TOKEN=${random_uuid.management_tokens[0].result}
  export CONSUL_CACERT=${abspath(path.module)}/alpha/cacert.pem
  EOT
}

resource "local_file" "alphaCACert" {
  filename = "${path.module}/alpha/cacert.pem"
  content  = module.certificate_authorities[0].certificate_pem
}

resource "local_file" "betaEnvironment" {
  filename = "${path.module}/beta/env.sh"
  content  = <<-EOT
  export CONSUL_HTTP_ADDR=https://localhost:${local.beta_host_api_port}
  export CONSUL_HTTP_TOKEN=${random_uuid.management_tokens[1].result}
  export CONSUL_CACERT=${abspath(path.module)}/beta/cacert.pem
  EOT
}

resource "local_file" "betaCACert" {
  filename = "${path.module}/beta/cacert.pem"
  content  = module.certificate_authorities[1].certificate_pem
}