variable "namespace" {
   type = string
   description = "Kubernetes namespace to create the PeeringAcceptor CRD within"
}

variable "peer_name" {
  type = string
  description = "Name of the remote peer"
}

variable "peering_token" {
   sensitive = true
   type = string
   description = "Peering token used to establish the peering"
}