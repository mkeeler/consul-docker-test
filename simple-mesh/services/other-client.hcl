service {
  token = "${token}"
  name = "other-client"
  port = 8080
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "static-server"
            local_bind_port = 8080
            # So we can hit the upstream listener from the host directly
            local_bind_address = "0.0.0.0"
          }
        ]
      }
    }
  }
}
