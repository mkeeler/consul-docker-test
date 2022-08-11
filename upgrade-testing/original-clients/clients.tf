module "license" {
  source = "../../modules/license-env"
}

locals {
  servicesOSS = {
    "service-oss.hcl" : templatefile("../consul-configs/service.hcl", { "name" : "svc-oss", "port" : 1234, "ns" : "", "partition" : "" })
  }

  servicesEnt = {
    for partition in data.terraform_remote_state.provisioning.outputs.partitions :
    partition => merge([
      for ns in data.terraform_remote_state.provisioning.outputs.namespaces[partition] :
      {
        "service-${ns}.hcl" : templatefile("../consul-configs/service.hcl", { "name" : "svc-ns-${ns}", "port" : 23455, "ns" : ns, "partition" : partition })
      }
    ]...)
  }
}


module "clients" {
  for_each = data.terraform_remote_state.provisioning.outputs.partitions
  source   = "../../modules/clients"

  persistent_data = false
  datacenter      = "primary"
  default_config = merge(each.value == "default" ? local.servicesOSS : {}, local.enterprise ? local.servicesEnt[each.value] : {}, {
    "connect.hcl"   = file("../consul-configs/connect.hcl")
    "partition.hcl" = local.enterprise ? "partition = \"${each.value}\"" : "# should not set the partition"
    "logging.hcl" = file("../consul-configs/logging.hcl")
  })
  default_name_prefix     = "consul-client-original-${each.value}-"
  default_name_suffix     = local.cluster_id.name_suffix
  default_name_include_dc = false
  default_image           = local.consul_image.latest
  default_networks        = [data.terraform_remote_state.servers.outputs.network.name]

  extra_args = data.terraform_remote_state.servers.outputs.join

  env = module.license.license_docker_env

  labels = local.cluster_id.resource_labels

  clients = [{}, {}]
}
