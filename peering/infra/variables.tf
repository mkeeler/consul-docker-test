variable "use_cluster_id" {
  type        = bool
  default     = false
  description = "Append a cluster ID to docker resources"
}

variable "consul_image" {
  type        = string
  default     = ""
  description = "Name of the Consul container image to use for all clusters"
}

variable "enterprise" {
  type        = bool
  default     = false
  description = "Whether to use Consul Enterprise features"
}

variable "consul_version" {
  type        = string
  default     = "local"
  description = "Version of consul container to use. 'local' will default to using a locally built version of consul"
}

variable "high_availability" {
  type = bool
  default = false
  description = "When true, multiple 3 Consul servers will be run in each cluster instead of just 1"
}
