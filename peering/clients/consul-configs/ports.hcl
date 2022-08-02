ports {
  # Enable the HTTP server
  http = 8500
  # Enable the HTTPs server
  https = 8501
  # Enable the gRPC server
  grpc = 8502
}

addresses {
   http = "127.0.0.1"
   https = "0.0.0.0"
   grpc = "127.0.0.1"
}