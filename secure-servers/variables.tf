variable "num_servers" {
  type        = number
  default     = 3
  description = "The number of servers to deploy"
}

variable "datacenter" {
  type        = string
  default     = "primary"
  description = "The datacenter name to use for the servers configuration"
}
