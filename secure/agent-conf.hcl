# Typical Configuration
primary_datacenter = "primary"

connect {
  enabled = true
}

# Turn on Gossip Encryption - the key was generated with: consul keygen
encrypt = "p6GprDqXmXEZm+QzFqM5OnwskMS/YyrgaaON/bS+K9w="
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

# Turn on ACLs in default deny mode
acl {
  enabled = true
  default_policy = "deny"
  tokens {
    # Setup a bunch of tokens, Normally the master token would not also be
    # the agent and replication token but it eases having terraform create
    # my demo cluster.
    master = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    agent = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    replication = "df87bdaa-b277-42d5-9b40-98d5d0fba61f"
    agent_master = "448eada4-df07-4633-8a17-d0ba7147cde4"
  }
}

# TLS certificate configured by modules

ports {
  # Disable the HTTP server
  http = -1
  # Enable the HTTPs server
  https = 8501
}

# Enable client cert verification for all RPCs
verify_incoming_rpc = true
# Disable client cert verficiation for the HTTPs servers
verify_incoming_https = false
# Enable strict TLS certificate verification for all outbound
# connections - this is mainly just RPCs from clients to servers
# or amongst servers
verify_outgoing = true
# Enable hostname verification during
verify_server_hostname = true