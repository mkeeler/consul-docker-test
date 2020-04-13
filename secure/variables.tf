variable "consul_image" {
   type = string
   default = "consul-dev"
   description = "Name of the Consul container image to use"
}

variable "use_cluster_id" {
   type = bool
   default = false
   description = "Whether to append a cluster id to docker resources"
}

variable "tls_ca_cert_file" {
   type = string
   default = "consul-agent-ca.pem"
   description = "CA Certificate (PEM Encoded)"
}

variable "tls_ca_key_file" {
   type = string
   default = "consul-agent-ca-key.pem"
   description = "CA Private Key (PEM Encoded) used for generating the server and client certificates"
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