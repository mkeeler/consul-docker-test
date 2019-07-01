service {
  name = "socat"
  port = 8181
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
