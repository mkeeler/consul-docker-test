variable "http_port" {
  type        = number
  default     = 8080
  description = "Port number to listen for HTTP requests on"
}

variable "grpc_port" {
  type        = number
  default     = 9090
  description = "Port number to listen for gRPC requests on"
}

variable "name" {
  type        = string
  description = "Name of the fortio container"
}

variable "network_mode" {
  type        = string
  default     = ""
  description = "The docker resources network mode"
}
