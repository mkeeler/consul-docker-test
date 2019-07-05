service {
  name = "api"
  port = 80
  meta {
    version = "2"
  }
  connect {
    sidecar_service {
      proxy {
        config {
          envoy_prometheus_bind_addr = "0.0.0.0:7777"
        }
      }
    }
  }
}
