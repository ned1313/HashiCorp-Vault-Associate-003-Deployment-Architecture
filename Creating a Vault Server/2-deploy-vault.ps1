# PowerShell script to deploy a Vault server using Docker

# Create Docker network for Vault
docker network create vault-network

# Deploy Vault server
$currentPath = (Get-Location).Path
docker run -d --name vault-0 `
  --cap-add=IPC_LOCK `
  -p 8200:8200 `
  -v "${currentPath}\config\vault-0:/vault/config" `
  -v "${currentPath}\data\vault-0:/vault/data" `
  --network vault-network `
  hashicorp/vault:1.17.0 server

docker ps

# Check Vault status
$env:VAULT_ADDR = "https://127.0.0.1:8200"
$env:VAULT_TLS_SERVER_NAME = "vault-0"
$env:VAULT_CACERT = "${currentPath}\config\vault-0\ca.crt"

vault status