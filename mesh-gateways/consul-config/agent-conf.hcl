primary_datacenter = "primary"

translate_wan_addrs = true
connect {
  enabled = true
}
telemetry {
  prometheus_retention_time = "168h"
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
      MeshGateway {
        Mode = "local"
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
    {
      Kind = "service-resolver"
      Name = "api"
      Redirect {
        Datacenter = "secondary"
      }
    }
    // {
    //   Kind = "service-splitter"
    //   Name = "api"
    //   Splits = [
    //     {
    //       Weight = 90
    //       ServiceSubset = "v1"
    //     },
    //     {
    //       Weight = 10
    //       ServiceSubset = "v2"
    //     },
    //   ]
    // },
  ]
}