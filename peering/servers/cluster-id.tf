resource "random_string" "cluster_id" {
  length  = 4
  special = false
  upper   = false
}

locals {
  cluster_id_suffix = var.use_cluster_id ? "-${random_string.cluster_id.result}" : ""
  cluster_id        = var.use_cluster_id ? random_string.cluster_id.result : ""
  cluster_id_raw    = random_string.cluster_id.result
}
