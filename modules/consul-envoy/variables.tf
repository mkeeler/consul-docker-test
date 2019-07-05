variable "consul_envoy_image" {
  type = string
  description = "The container image to use that contains both Consul and Envoy"
}

variable "name" {
  type = string
  description = "The name of the container"
}

variable "consul_manager" {
  type = string
  description = "The name of consul container that will manage this envoy instance"
}

variable "container_network_inject" {
  type = bool
  default = true
  description = "Whether to inject envoy into the consul manager containers network namespace."
}

variable "networks" {
  type = list(string)
  default = []
  description = "List of networks to connect the container to. This is incompatibile with container_network_inject"
}

variable "uploads" {
  type = list(object({path=string, content=string}))
  default = []
  description = "Extra files to upload into the container"
}

variable "env" {
  type = list(string)
  default = []
  description = "Extra environment variables to set for the container"
}

variable "admin_access_log" {
  type = string
  default = "/dev/null"
  description = "Value for the -admin-access-log-path CLI option"
}

variable "register" {
  type = bool
  default = false
  description = "Enable registration of the mesh gateway service"
}

variable "expose_admin" {
  type = bool
  default = false
  description = "Whether to expose the admin interface on the Docker host"
}

variable "admin_host_port" {
  type = number
  default = 19000
  description = "Host port to use for the Envoy admin interface"
}

variable "mesh_gateway" {
  type = bool
  default = false
  description = "Enable configuration as a mesh gateway"
}

variable "no_central_config" {
  type = bool
  default = false
  description = "Disables central configuration"
}

variable "proxy_id" {
  type = string
  default = ""
  description = "The proxy's id on the local agent"
}

variable "service_name" {
  type = string
  default = "mesh-gateway"
  description = "The name of the mesh-gateway service to use during registration"
}

variable "sidecar_for" {
  type = string
  default = ""
  description = "The ID of a service instance on the local agent that this proxy should become a sidecar for"
}

variable "address" {
  type = string
  default = "{{ GetInterfaceIP \"eth0\" }}:8443"
  description = "The IP address to register as the mesh-gateway services LAN address. Can be a go-sockaddr template"
}

variable "wan_address" {
  type = string
  default = "{{ GetInterfaceIP \"eth1\" }}:8443"
  description = "The IP address to register as the mesh-gateway services WAN address. Can be a go-sockaddr template"
}

variable "log_level" {
  type = string
  default = "debug"
  description = "The log level for Envoy info,debug,trace etc."
}


