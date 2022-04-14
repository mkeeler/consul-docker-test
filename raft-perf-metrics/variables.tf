variable "consul_image" {
   type = string
   default = "consul:latest"
   description = "Name of the Consul container image to use"
}

variable "use_cluster_id" {
   type = bool
   default = false
   description = "Whether to append a cluster id to docker resources"
}