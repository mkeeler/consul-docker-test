variable "algorithm" {
  type        = string
  default     = "ES384"
  description = "Desired JWT signing algorithm."

  validation {
    condition     = contains(["RS256", "RS384", "RS512", "ES256", "ES384", "ES512"], var.algorithm)
    error_message = "The JWT algorithm must be one of RS256, RS384, RS512, ES256, ES384 or ES512"
  }
}
