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
  default = "consul-server-"
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

variable "servers" {
  type = any
  description = "List of server configuration maps - valid map keys are: name (string), image (string), hostname (string), networks (list of strings), ports"
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

variable "enable_healthcheck" {
  type = bool
  default = false
  description = "Whether to enable a container health check which will monitor that this server is attached to a datacenter with a leader"
}

variable "healthcheck_endpoint" {
  type = string
  default = "localhost:8500"
  description = "The local Consul API address that should be used within the container"
}

variable "tls_enabled" {
  type = bool
  default = false
  description = "Enable setting up TLS for the servers. Requires setting tls_ca_cert and tls_ca_key"
}

variable "tls_ca_cert" {
  type = string
  default = ""
  description = "CA Certificate PEM"
}

variable "tls_ca_key" {
  type = string
  default = ""
  description = "CA Private Key"
}

variable "tls_ca_key_type" {
  type = string
  default = "ECDSA"
  description = "CA private key type"
}

variable "tls_validity_days" {
  type = number
  default = 7
  description = "Number of days the generated certificates will be valid for"
}

variable "tls_organization" {
   type = string
   default = "HashiCorp Inc."
   description = "Organization to put in all certificate subjects"
}

variable "tls_organizational_unit" {
   type = string
   default = "Consul Docker Test"
   description = "Organizational Unit to put in all certificate subjects"
}

variable "tls_country" {
   type = string
   default = "US"
   description = "Country to put in all certificate subjects"
}

variable "tls_province" {
   type = string
   default = "NC"
   description = "Province or state to put in all certificate subjects"
}

variable "tls_locality" {
   type = string
   default = "Raliegh"
   description = "Locality or city to put in all certificate subjects"
}

variable "tls_street_address" {
   type = list(string)
   default = []
   description = "Street addresses to put in all certificate subjects"
}

variable "tls_postal_code" {
   type = string
   default = ""
   description = "Postal Code to put in all certificate subjects"
}

variable "segments" {
  type = any
  default = {}
  description = "Map of segment names to the segment configuration"
}

variable "bootstrap" {
  type = bool
  default = true
  description = "whether to bootstrap raft"
}

variable "bootstrap_expect" {
  type = number
  default = 0
  description = "number of servers to require before bootstrapping"
}