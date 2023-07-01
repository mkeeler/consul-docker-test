variable "consul_image" {
  type        = string
  default     = "consul:local"
  description = "Name of the Consul container image to use"
}

variable "consul_envoy_image" {
  type        = string
  default     = "consul-envoy"
  description = "Name of the combined Consul + Envoy image to use"
}

variable "use_cluster_id" {
  type        = bool
  default     = false
  description = "Whether to append a cluster id to docker resources"
}

variable "network_name" {
  type        = string
  default     = "consul"
  description = "Name of the network to create. If use_cluster_id is set then the cluster id resource name suffix will be appended to this"
}
