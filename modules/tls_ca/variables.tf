variable "days" {
  type        = number
  default     = 7
  description = "Number of days this CA will be valid for"
}

variable "common_name" {
  type        = string
  default     = "Consul CA"
  description = "Common name to assign the certificate"
}

variable "organization" {
  type        = string
  default     = "HashiCorp Inc."
  description = "Organization to put in the certificates subject"
}

variable "organizational_unit" {
  type        = string
  default     = "Consul Docker Test"
  description = "Organizational Unit to put in the certificates subject"
}

variable "country" {
  type        = string
  default     = "US"
  description = "Country to put in the certificates subject"
}

variable "province" {
  type        = string
  default     = "NC"
  description = "Province or state to put in the certificates subject"
}

variable "locality" {
  type        = string
  default     = "Raliegh"
  description = "Locality or city to put in the certificates subject"
}

variable "street_address" {
  type        = list(string)
  default     = []
  description = "Street addresses to put in the certificates subject"
}

variable "postal_code" {
  type        = string
  default     = ""
  description = "Postal Code to put in the certificates subject"
}

variable "serial_number" {
  type        = string
  default     = ""
  description = "Serial number to put in the certificates subject"
}

variable "dns_names" {
  type        = list(string)
  default     = []
  description = "Additional DNS names to add to the certificate"
}

variable "disable_default_dns_names" {
  type        = bool
  default     = false
  description = "Disable appending the default DNS names to the list of dns_names"
}

variable "root_ca" {
  type = object({
    private_key_pem    = string
    certificate_pem    = string
    certificate_bundle = string
  })
  default     = null
  description = "Root CA to use for signing this CA certificate"
}
