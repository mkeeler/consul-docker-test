# enable grpc
ports {
   grpc = 8502
   http = 8500
   https = 8501
}

datacenter = "primary"
primary_datacenter = "primary"

log_level = "debug"

# Enable ACLs
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

# Turn on Gossip Encryption - the key was generated with: consul keygen
encrypt = "p6GprDqXmXEZm+QzFqM5OnwskMS/YyrgaaON/bS+K9w="
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

telemetry {
  prometheus_retention_time = "1h"
  disable_hostname = true
  disable_compat_1.9 = true
}

connect {
  enabled = true
}

tls {
   defaults {
      verify_outgoing = true
      verify_incoming = true
   }
   
   internal_rpc {
      verify_server_hostname = true
   }
   
   grpc {
      verify_incoming = false
   }
}