variable "consul_image" {
  type        = string
  default     = ""
  description = "Name of the Consu lcontainer image to use as the original version"
}

variable "enterprise" {
  type        = bool
  default     = false
  description = "Whether to use enterprise features"
}
