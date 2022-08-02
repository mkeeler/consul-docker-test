# TLS certificate configured by modules
tls {
  defaults {
    // path to certs is configured within the "servers" module
    tls_min_version   = "TLSv1_3"
    verify_incoming   = true
    verify_outgoing   = true
  }
  https {
    tls_min_version = "TLSv1_2" # terraform consul provider
    verify_incoming = false
  }
  internal_rpc {
    verify_server_hostname = true
  }
  grpc {
    verify_incoming = false
  }
}