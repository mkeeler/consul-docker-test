variable "name" {
  type        = string
  description = "Name of the cluster"
}

variable "enable_tls" {
  type        = bool
  default     = false
  description = "Enable TLS communications within the cluster"
}

variable "ca" {
  type = object({
    private_key_pem = string
    certificate_pem = string
    certificate_bundle = string
  })
  default     = null
  description = "CA to use for this clusters certificates"
}

variable "generate_intermediate_ca" {
  type = bool
  default = true
  description = "Generate an intermediate CA signed by the root/intermediate CA specified by the `ca` variable"
}

variable "gossip_key" {
  type        = string
  default     = ""
  description = "Gossip encryption key to use. If not provided and gossip encryption is enabled then a new key will be generated"
}

variable "license" {
  type        = string
  default     = ""
  description = "Consul Enterprise license"
}

variable "enterprise" {
  type        = bool
  default     = false
  description = "Whether to enable Consul Enterprise features"
}

variable "image" {
  type        = string
  default     = ""
  description = "Override the Consul container image used"
}

variable "consul_version" {
  type        = string
  default     = "local"
  description = "Override the Consul version used"
}

variable "values" {
  type        = map(string)
  default     = {}
  description = "Additional values to set in the helm values. These will override any set internally by the module"
}

variable "yaml_values" {
  type = list(string)
  default = []
  description = "Additional values to set in the helm values."
}

variable "bootstrap_token" {
  type = string
  default = ""
  sensitive = true
  description = "ACL Bootstrap token to inject"
}