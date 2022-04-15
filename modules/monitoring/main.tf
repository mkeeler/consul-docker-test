
locals {
   promcfg = templatefile("${path.module}/prometheus/prometheus.yml", {"jobs": var.prometheus_jobs})
}


module "prometheus" {
  source = "../prometheus"

  container_name = var.prometheus_container_name
  unique_id = var.unique_id
  networks  = var.networks
  config    = local.promcfg
  host_port = var.prometheus_port_mapping
}

module "grafana" {
  source = "../grafana"

  env = var.env
  container_name = var.grafana_container_name
  host_port = var.grafana_port_mapping
  unique_id = var.unique_id
  provisioning = [
    {
      type    = "datasource"
      name    = "datasource.yaml"
      content = templatefile("${path.module}/grafana/prometheus-data-source.yaml", { "prometheus_address" : "${module.prometheus.container.name}:9090" })
    },
    {
      type    = "dashboard"
      name    = "dashboards.yml"
      content = file("${path.module}/grafana/dashboards.yml")
    },
    {
      type    = "dashboard"
      name    = "raft-performance.json"
      content = file("${path.module}/grafana/raft-performance.json")
    },
    {
      type    = "dashboard"
      name    = "performance.json"
      content = file("${path.module}/grafana/performance.json")
    },
  ]
  networks = var.networks
}