primary_datacenter = "primary"

translate_wan_addrs = true

acl {
  enabled = true
  default_policy = "deny"
  tokens {
    managed_service_provider = [
      {
        # token to be used for replication by servers in secondary datacenters
        # also used as the main token for registering themselves in the secondary
        # dc's catalog
        accessor_id = "6a615963-280b-4580-a185-216d9bcc74e5"
        secret_id = "8bfd01c2-1580-4839-bc76-ce925f8e8ed0"
      }
    ]
    agent_master = "448eada4-df07-4633-8a17-d0ba7147cde4"
  }
  enable_token_replication = true
}


connect {
  enabled = true
}
