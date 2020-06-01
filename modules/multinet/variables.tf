variable "networks" {
  type = list(string)
  default = ["consul-net"]
  description = "Name of docker networks to create"
}

variable "append_cluster_id" {
   type = bool
   default = false
   description = "Whether to append the cluster id to the network names"
}

variable "cluster_id" {
   type = string
   default = ""
   description = "Cluster ID to add to network names"
}