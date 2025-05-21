# Update the configuration file for vault-0
<# 
retry_join {
  leader_api_addr = "https://vault-0:8200"
  leader_ca_cert_file = "/vault/config/ca.crt"
}

retry_join {
  leader_api_addr = "https://vault-1:8200"
  leader_ca_cert_file = "/vault/config/ca.crt"
}

retry_join {
  leader_api_addr = "https://vault-2:8200"
  leader_ca_cert_file = "/vault/config/ca.crt"
}
#>

# Restart vault-0 container to apply changes
docker container restart vault-0

# Deploy Vault server 1
$currentPath = (Get-Location).Path
docker run -d --name vault-1 `
  --cap-add=IPC_LOCK `
  -p 8210:8200 `
  -v "${currentPath}\config\vault-1:/vault/config" `
  -v "${currentPath}\data\vault-1:/vault/data" `
  --network vault-network `
  hashicorp/vault:1.17.0 server

# Deploy Vault server 2
docker run -d --name vault-2 `
  --cap-add=IPC_LOCK `
  -p 8220:8200 `
  -v "${currentPath}\config\vault-2:/vault/config" `
  -v "${currentPath}\data\vault-2:/vault/data" `
  --network vault-network `
  hashicorp/vault:1.17.0 server

# Check Vault status of vault-1 and vault-2
vault status -address="https://127.0.0.1:8210" -tls-server-name="vault-1" -ca-cert="${currentPath}\config\vault-1\ca.crt"
vault status -address="https://127.0.0.1:8220" -tls-server-name="vault-2" -ca-cert="${currentPath}\config\vault-2\ca.crt"

# Initialize Vault servers
$env:VAULT_ADDR = "https://127.0.0.1:8200"
$env:VAULT_TLS_SERVER_NAME = "vault-0"
$env:VAULT_CACERT = "${currentPath}\config\vault-0\ca.crt"

vault operator init -key-shares=1 -key-threshold=1
vault operator unseal

$env:VAULT_ADDR = "https://127.0.0.1:8210"
$env:VAULT_TLS_SERVER_NAME = "vault-1"
$env:VAULT_CACERT = "${currentPath}\config\vault-1\ca.crt"

vault status
vault operator unseal

$env:VAULT_ADDR = "https://127.0.0.1:8220"
$env:VAULT_TLS_SERVER_NAME = "vault-2"
$env:VAULT_CACERT = "${currentPath}\config\vault-2\ca.crt"

vault status
vault operator unseal

vault login
vault operator raft list-peers

# Mount a secret engine and write a secret to the cluster
vault secrets enable -path=secret kv-v2
vault kv put secret/mysecret username="admin" password="password"

# Read the secret from the cluster
vault kv get secret/mysecret

# Force vault-0 to step down
vault operator members
vault operator step-down
vault operator members

# Get the secret again
vault kv get secret/mysecret

# Stop the active node
docker container stop vault-1
vault operator members
vault operator raft list-peers

# Get the secret again
vault kv get secret/mysecret

# Remove the cluster and clean up the containers
docker container stop vault-0 vault-1 vault-2
docker container rm vault-0 vault-1 vault-2
docker network rm vault-network

# Clean up the data directories
Remove-Item -Path "${currentPath}\data" -Recurse -Force
Remove-Item -Path "${currentPath}\config\vault-0" -Recurse -Force
Remove-Item -Path "${currentPath}\config\vault-1" -Recurse -Force
Remove-Item -Path "${currentPath}\config\vault-2" -Recurse -Force
Remove-Item -Path "${currentPath}\certificates" -Recurse -Force