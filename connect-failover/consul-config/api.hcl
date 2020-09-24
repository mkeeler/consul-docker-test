service {
  name = "api"
  port = 8080
  meta {
    version = "1"
  }
  connect {
    sidecar_service {}
  }
}
