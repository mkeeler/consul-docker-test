service {
  name = "tcpproxy"
  port = 8181
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "socat"
            datacenter = "primary"
            local_bind_port = 10000
          }
        ]
        config {
          envoy_prometheus_bind_addr = "0.0.0.0:7777"
        }
      }
    }
  }
}
