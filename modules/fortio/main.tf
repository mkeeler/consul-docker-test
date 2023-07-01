resource "docker_image" "fortio" {
  name         = "fortio/fortio"
  keep_locally = true
}

resource "docker_container" "fortio" {
  image = docker_image.fortio.image_id
  name  = var.name

  network_mode = var.network_mode

  command = [
    "server",
    "-http-port", tostring(var.http_port),
    "-grpc-port", tostring(var.grpc_port),
    "-redirect-port", "disabled",
  ]

  env = [
    "FORTIO_NAME=${var.name}"
  ]
}
