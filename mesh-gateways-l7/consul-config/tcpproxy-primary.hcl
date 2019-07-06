service {
  name = "tcpproxy"
  port = 8181
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "socat"
            datacenter = "secondary"
            local_bind_port = 10000
          }
        ]
      }
    }
  }
}
