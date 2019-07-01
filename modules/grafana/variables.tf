variable "container_name" {
  type = string
  default = "grafana"
  description = "The name of the container"
}

variable "unique_id" {
  type = string
  default = ""
  description = "A unique string to append to the docker"
}

variable "disable_host_port" {
  type = bool
  default = false
  description = "Set this to disable port mapping"
}

variable "host_port" {
  type = number
  default = 3000
  description = "The port to map to the docker host to access grafana"
}

// The GF_SERVER_ROOT_URL will be synthesized if unset
variable "env" {
  type = map(string)
  default = {}
  description = "A map containing environment variables and their values"
}

variable "networks" {
  type = list(string)
  default = []
  description = "List of networks to connect the container to"
}

variable "provisioning" {
  type = list(object({type=string, name=string, content=string}))
  default = []
  description = "List of files to provision grafana with"
}