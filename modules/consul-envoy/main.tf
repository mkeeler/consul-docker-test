locals {
   admin_args = var.expose_admin ? ["-admin-bind", "0.0.0.0:19000"] : []
   access_log_args = ["-admin-access-log-path", var.admin_access_log]
   mesh_gateway_args = var.mesh_gateway && var.sidecar_for == "" ? concat(
      ["-mesh-gateway"],
      !var.register ? [] : concat(
         ["-register"],
         var.address != "" ? ["-address", var.address]: [],
         var.wan_address != "" ? ["-wan-address", var.wan_address]: [],
         var.service_name != "" ? ["-service", var.service_name]: []
      )
   ) : []
   sidecar_args = var.sidecar_for != "" && !var.mesh_gateway ? ["-sidecar-for", var.sidecar_for] : []
   proxy_id_args = var.proxy_id != "" ? ["-proxy-id", var.proxy_id] : []
   central_config_args = var.no_central_config ? ["-no-central-config"] : []

   command = concat(
      ["/bin/consul", "connect", "envoy"],
      local.mesh_gateway_args,
      local.sidecar_args,
      local.proxy_id_args,
      local.central_config_args,
      local.access_log_args,
      local.admin_args
   )

   ports = var.expose_admin && !var.container_network_inject ? [var.admin_host_port] : []
}

resource "docker_container" "consul-envoy" {
   image = var.consul_envoy_image
   name = var.name
   hostname = var.container_network_inject ? "" : var.name
   network_mode = var.container_network_inject ? "container:${var.consul_manager}" : ""
   env = var.env
   dynamic networks_advanced {
      for_each = var.container_network_inject ? [] : var.networks

      content {
         name = networks_advanced.name
      }
   }

   dynamic "upload" {
      for_each = var.uploads

      content {
         content = upload.content
         file = upload.path
      }
   }

   dynamic "ports" {
      for_each = local.ports
      content {
         internal = 19000
         external = ports.value
         protocol = "tcp"
      }
   }

   command = local.command
}