# Create Docker network for Vault
docker network create vault-network

# Deploy Vault server
echo "Deploying Vault server..."
docker run -d --name vault-0 \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -v "$(pwd)/config/vault-0:/vault/config" \
  -v "$(pwd)/data/vault-0:/vault/data" \
  --network vault-network \
  hashicorp/vault:1.17.0 server


# Check Vault status
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true

vault status