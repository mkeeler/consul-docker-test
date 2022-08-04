module "license" {
  source = "../../modules/license-env"
}

module "clients" {
  for_each = data.terraform_remote_state.provisioning.outputs.partitions
  source   = "../../modules/clients"

  persistent_data = false
  datacenter      = "primary"
  default_config = {
    "connect.hcl"   = file("../consul-configs/connect.hcl")
    "partition.hcl" = local.enterprise ? "partition = \"${each.value}\"" : "# should not set the partition"
  }
  default_name_prefix     = "consul-client-upgraded-${each.value}-"
  default_name_suffix     = local.cluster_id.name_suffix
  default_name_include_dc = false
  default_image           = local.consul_image.latest
  default_networks        = [data.terraform_remote_state.servers.outputs.network.name]

  extra_args = data.terraform_remote_state.servers.outputs.join

  env = module.license.license_docker_env

  labels = local.cluster_id.resource_labels

  clients = [{}, {}]
}
