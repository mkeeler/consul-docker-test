variable "namespace" {
   type = string
   description = "Kubernetes namespace to create the PeeringAcceptor CRD within"
}

variable "peer_name" {
  type = string
  description = "Name of the remote peer"
}