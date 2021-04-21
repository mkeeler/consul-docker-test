primary_datacenter = "primary"

translate_wan_addrs = true

acl {
  enabled = true
  default_policy = "deny"
  enable_token_replication = true
  tokens {
    master = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    agent = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    replication = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    agent_master = "448eada4-df07-4633-8a17-d0ba7147cde4"
  }
}

telemetry {
  prometheus_retention_time = "168h"
}

connect {
  enabled = true
}
