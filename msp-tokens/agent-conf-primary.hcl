primary_datacenter = "primary"

translate_wan_addrs = true

acl {
  enabled = true
  default_policy = "deny"
  tokens {
    managed_service_provider = [
       {
          # main token to be by servers in the primary datacenter
          accessor_id = "c5f333e2-c590-4eea-8b2c-ed0d8e50c6dc"
          secret_id = "c3f9ce9a-7e3b-4e37-9a04-b64ff2453f3e"
       },
       {
         # token to be used for replication by servers in secondary datacenters
         accessor_id = "6a615963-280b-4580-a185-216d9bcc74e5"
         secret_id = "8bfd01c2-1580-4839-bc76-ce925f8e8ed0"
       }
    ]
    agent_master = "448eada4-df07-4633-8a17-d0ba7147cde4"
  }
}


connect {
  enabled = true
}
