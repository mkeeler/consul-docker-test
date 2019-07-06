service {
  name = "web"
  port = 80
  connect {
    sidecar_service {
      proxy {
        upstreams = [
          {
            destination_name = "api"
            local_bind_port = 10000
            //datacenter = "secondary"
            # So we can hit the upstream listener from the host directly
            local_bind_address = "0.0.0.0"
          }
        ]
      }
    }
  }
}
