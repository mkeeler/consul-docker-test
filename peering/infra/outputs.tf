output "cluster_id" {
  value = module.cluster_id
}

output "license" {
  value = module.license
}

output "gamma_k8s_context" {
  value = "k3d-${k3d_cluster.gamma.name}"
}

output "delta_k8s_context" {
  value = var.enterprise ? "k3d-${k3d_cluster.delta[0].name}" : ""
}

output "consul_image" {
  value = docker_image.consul
}

output "enterprise" {
  value = var.enterprise
}

output "ca" {
  sensitive = true
  value     = module.certificate_authority
}

output "network" {
  value = docker_network.network
}

output "high_availability" {
  value = var.high_availability
}
