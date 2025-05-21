#!/bin/bash
# Script to deploy a Vault server using Docker

# Create Docker network for Vault
echo "Creating Docker network for Vault..."
docker network create vault-network || echo "Network already exists"

# Deploy Vault server
echo "Deploying Vault server..."
docker run -d --name vault-0 \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -v "$(pwd)/config/vault-0:/vault/config" \
  -v "$(pwd)/data/vault-0:/vault/data" \
  --network vault-network \
  hashicorp/vault:1.17.0 server

echo "Waiting for Vault to start..."
sleep 5

# Check Vault status
echo "Checking Vault status..."
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true

vault status || echo "Vault is not yet initialized"

echo "Vault server deployment complete!"
echo ""
echo "To use your Vault server:"
echo "export VAULT_ADDR=https://127.0.0.1:8200"
echo "export VAULT_SKIP_VERIFY=true"
echo ""
echo "Initialize Vault with: vault operator init"
echo "Unseal Vault with: vault operator unseal"