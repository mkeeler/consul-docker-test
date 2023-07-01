service {
  token = "${token}"
  name = "static-server"
  port = 8080
  connect {
    sidecar_service {}
  }
}
