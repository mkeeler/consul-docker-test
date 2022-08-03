locals {
  cluster_id        = data.terraform_remote_state.servers.outputs.cluster_id
  cluster_id_raw    = data.terraform_remote_state.servers.outputs.cluster_id_raw
  cluster_id_suffix = data.terraform_remote_state.servers.outputs.cluster_id_suffix
}
