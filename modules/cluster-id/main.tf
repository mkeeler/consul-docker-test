variable "resources_include_cluster_id" {
  type        = bool
  default     = true
  description = "Configure outputs to assume Docker resources will include the cluster ID"
}

resource "random_string" "cluster_id" {
  length  = 4
  special = false
  upper   = false
}

output "id" {
  value = random_string.cluster_id.result
}

output "id_or_empty" {
  value = var.resources_include_cluster_id ? random_string.cluster_id.result : ""
}

output "name_suffix" {
  value = var.resources_include_cluster_id ? "-${random_string.cluster_id.result}" : ""
}

output "resource_labels" {
  value = {
    "consul_tf_id" : random_string.cluster_id.result
  }
}
