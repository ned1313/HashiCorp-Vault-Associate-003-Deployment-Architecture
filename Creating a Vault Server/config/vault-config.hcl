ui = true
disable_mlock = true

storage "raft" {
  path = "/vault/data"
        
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file = "/vault/config/tls.crt"
  tls_key_file  = "/vault/config/tls.key"
  tls_client_ca_file = "/vault/config/ca.crt"
}

api_addr = "https://vault-0:8200"
cluster_addr = "https://vault-0:8201"
