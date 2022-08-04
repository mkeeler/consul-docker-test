variable "consul_image" {
  type        = string
  default     = ""
  description = "Name of the Consu lcontainer image to use as the original version"
}

variable "enterprise" {
  type        = bool
  default     = false
  description = "Whether to use enterprise features"
}

variable "use_cluster_id" {
  type        = bool
  default     = false
  description = "Whether to appen a cluster id to docker resource names"
}
