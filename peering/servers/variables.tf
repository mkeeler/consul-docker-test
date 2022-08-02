variable "consul_image" {
  type        = string
  default     = "hashicorp/consul-enterprise:local"
  description = "Name of the Consul container image to use for all clusters"
}

variable "use_cluster_id" {
  type        = bool
  default     = false
  description = "Append a cluster ID to docker resources"
}
