# Turn on ACLs in default deny mode
acl {
  enabled = true
  default_policy = "deny"
  tokens {
    # Setup a bunch of tokens, Normally the master token would not also be
    # the agent and replication token but it eases having terraform create
    # my demo cluster.
    agent = "${agent}"
    agent_recovery = "${recovery}"
  }
}