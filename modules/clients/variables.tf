variable "persistent_data" {
  type = bool
  default = true
  description = "Whether Docker volumes should be created and used by the servers for persistent storage"
}

variable "datacenter" {
  type = string
  default = "dc1"
  description = "The datacenter name to configure these servers with"
}

variable "default_config" {
  type = map(string)
  default = {}
  description = "Mapping of configuration file names to the string contents to embed within the containers"
}

variable "default_image" {
  type = string
  default = "consul:latest"
  description = "Default Consul Docker image to use for the server containers"
}

variable "default_name_prefix" {
  type = string
  default = "consul-client-"
  description = "Default prefix to use for container's name and hostname"
}

variable "default_name_suffix" {
  type = string
  default =""
  description = "Default suffix to use for container's name and hostname"
}

variable "default_name_include_dc" {
  type = bool
  default = true
  description = "Whether generated container names and hostnames should include the datacenter"
}


variable "default_networks" {
  type = list(string)
  default = ["consul-net"]
  description = "Name of the docker networks to attach these containers to"
}

variable "clients" {
  type = any
  description = "List of client configuration objects"
}

variable "extra_args" {
  type = list(string)
  default = []
  description = "Extra consul agent arguments to append to the main invocation"
}

variable "env" {
  type = list(string)
  default=[]
  description = "Environment variables to set for the container"
}

