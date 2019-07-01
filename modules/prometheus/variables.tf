variable "container_name" {
  type = string
  default = "prometheus"
  description = "The name of the container"
}

variable "unique_id" {
  type = string
  default = ""
  description = "A unique string to append to the docker resources"
}

variable "disable_host_port" {
  type = bool
  default = false
  description = "Set this to disable port mapping"
}

variable "host_port" {
  type = number
  default = 9090
  description = "The port to map to the docker host to access grafana"
}

variable "networks" {
  type = list(string)
  default = []
  description = "List of networks to connect the container to"
}

variable "config" {
  type = string
  default = ""
  description = "Prometheus configuration"
}