data "external" "env" {
   program = ["jq", "--null-input", "env | with_entries(select(.key | test(\"^CONSUL_LICENSE$|^CONSUL_LICENSE_PATH$\")))"]
}

locals {
   license_signed = lookup(data.external.env.result, "CONSUL_LICENSE", "")
   license_path = lookup(data.external.env.result, "CONSUL_LICENSE_PATH", "")
   license_path_signed = local.license_path != "" ? file(local.license_path) : ""
   
   license = local.license_signed != "" ? local.license_signed : local.license_path_signed
}