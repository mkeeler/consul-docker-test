variable "consul_image" {
  type        = string
  default     = ""
  description = "Name of the Consul container image to use for all clusters"
}

variable "use_cluster_id" {
  type        = bool
  default     = false
  description = "Append a cluster ID to docker resources"
}

variable "enterprise" {
  type        = bool
  default     = true
  description = "Whether to use enterprise features"
}

variable "disable_provisioning" {
  type        = bool
  default     = false
  description = "Disable provisioning of partitions and setting up peering"
}
