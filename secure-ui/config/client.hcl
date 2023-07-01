# Typical Configuration
primary_datacenter = "${datacenter}"

connect {
  enabled = true
}

# Turn on Gossip Encryption - the key was generated with: consul keygen
encrypt = "${gossip_key}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true

# Turn on ACLs in default deny mode
acl {
  enabled = true
  default_policy = "deny"
  tokens {
    agent = "${agent_token}"
    agent_recovery = "${recovery_token}"
  }
}

# TLS certificate configured by modules

ports {
  http = -1
  https = 8501
  grpc = -1
  grpc_tls = 8503
}

tls {
  defaults {
    tls_min_version   = "TLSv1_3"
    verify_incoming   = true
    verify_outgoing   = true
  }
  https {
    tls_min_version = "TLSv1_2"
    verify_incoming = false
  }
  internal_rpc {
    verify_server_hostname = true
  }
  grpc {
    verify_incoming = false
  }
}