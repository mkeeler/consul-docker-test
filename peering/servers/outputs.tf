output "alpha_api" {
  value = "https://localhost:${local.exposedAPIPorts[0]}"
}

output "beta_api" {
  value = "https://localhost:${local.exposedAPIPorts[1]}"
}

output "alpha_ca_cert" {
  value = module.certificate_authorities[0].cert.cert_pem
}

output "beta_ca_cert" {
  value = module.certificate_authorities[1].cert.cert_pem
}

output "alpha_ca_key" {
  sensitive = true
  value     = module.certificate_authorities[0].cert.private_key_pem
}

output "beta_ca_key" {
  sensitive = true
  value     = module.certificate_authorities[1].cert.private_key_pem
}

output "alpha_token" {
  sensitive = true
  value     = random_uuid.management_tokens[0].result
}

output "beta_token" {
  sensitive = true
  value     = random_uuid.management_tokens[1].result
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

output "enterprise" {
  value = var.enterprise
}

output "alpha" {
  sensitive = true
  value = {
    "tokens" : {
      "management" : random_uuid.management_tokens[0].result,
      "recovery" : random_uuid.recovery_tokens[0].result
    },
    "ca" : {
      "key" : module.certificate_authorities[0].key.private_key_pem,
      "cert" : module.certificate_authorities[0].cert.cert_pem
    },
    "gossip_key" : random_id.gossip_keys[0].b64_std,
    "join" : module.clusters[0].join,
    "hostnames" : module.clusters[0].server_hostnames,
    "api" : "https://localhost:${local.exposedAPIPorts[0]}"
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
      "key" : module.certificate_authorities[1].key.private_key_pem,
      "cert" : module.certificate_authorities[1].cert.cert_pem
    },
    "gossip_key" : random_id.gossip_keys[1].b64_std,
    "join" : module.clusters[1].join,
    "hostnames" : module.clusters[1].server_hostnames,
    "api" : "https://localhost:${local.exposedAPIPorts[1]}"
  }
}

output "consul_image" {
  value = local.default_image
}

output "cluster_id" {
  value = local.cluster_id
}

output "cluster_id_raw" {
  value = local.cluster_id_raw
}

output "cluster_id_suffix" {
  value = local.cluster_id_suffix
}

output "network" {
  value = docker_network.network.name
}

output "alpha_env" {
  value = "${path.module}/alpha/env.sh"
}

output "beta_env" {
  value = "${path.module}/alpha/env.sh"
}

resource "local_file" "alphaEnvironment" {
  filename = "${path.module}/alpha/env.sh"
  content  = <<-EOT
  export CONSUL_HTTP_ADDR=https://localhost:${local.exposedAPIPorts[0]}
  export CONSUL_HTTP_TOKEN=${random_uuid.management_tokens[0].result}
  export CONSUL_CACERT=${abspath(path.module)}/alpha/cacert.pem
  EOT
}

resource "local_file" "alphaCACert" {
  filename = "${path.module}/alpha/cacert.pem"
  content  = module.certificate_authorities[0].cert.cert_pem
}

resource "local_file" "betaEnvironment" {
  filename = "${path.module}/beta/env.sh"
  content  = <<-EOT
  export CONSUL_HTTP_ADDR=https://localhost:${local.exposedAPIPorts[1]}
  export CONSUL_HTTP_TOKEN=${random_uuid.management_tokens[1].result}
  export CONSUL_CACERT=${abspath(path.module)}/beta/cacert.pem
  EOT
}

resource "local_file" "betaCACert" {
  filename = "${path.module}/beta/cacert.pem"
  content  = module.certificate_authorities[1].cert.cert_pem
}
