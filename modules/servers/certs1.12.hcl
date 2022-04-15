# Setup paths to TLS keys and certificates
tls {
   defaults {
      ca_file = "/consul/config/tls/cacert.pem"
      cert_file = "/consul/config/tls/cert.pem"
      key_file = "/consul/config/tls/key.pem"
   }
}