primary_datacenter = "primary"

translate_wan_addrs = true

connect {
  enabled = true
}

enable_central_service_config = true

config_entries {
  bootstrap = [
    {
      Kind = "proxy-defaults"
      Name = "global"
      Config {
        local_connect_timeout_ms = 1000
        handshake_timeout_ms = 10000
      }
    },
    {
      Kind = "service-defaults"
      Name = "api"
      protocol = "http"
    },
    {
      Kind = "service-defaults"
      Name = "web"
      protocol = "http"
    },
  ]
}