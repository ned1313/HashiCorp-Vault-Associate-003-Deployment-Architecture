#!/bin/bash
# filepath: c:\gh\HashiCorp-Vault-Associate-003-Deployment-Architecture\Creating a Vault Server\4-add-servers-to-cluster.sh
# Script to add additional servers to a Vault cluster using Docker

# Update the configuration file for vault-0
# Note: The retry_join configuration should be added to your vault-config.hcl file
: '
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
'

# Restart vault-0 container to apply changes
docker container restart vault-0

# Deploy Vault server 1
docker run -d --name vault-1 \
  --cap-add=IPC_LOCK \
  -p 8210:8200 \
  -v "$(pwd)/config/vault-1:/vault/config" \
  -v "$(pwd)/data/vault-1:/vault/data" \
  --network vault-network \
  hashicorp/vault:1.17.0 server

# Deploy Vault server 2
docker run -d --name vault-2 \
  --cap-add=IPC_LOCK \
  -p 8220:8200 \
  -v "$(pwd)/config/vault-2:/vault/config" \
  -v "$(pwd)/data/vault-2:/vault/data" \
  --network vault-network \
  hashicorp/vault:1.17.0 server

# Check Vault status of vault-1 and vault-2
vault status -address="https://127.0.0.1:8210" -tls-server-name="vault-1" -ca-cert="$(pwd)/config/vault-1/ca.crt"
vault status -address="https://127.0.0.1:8220" -tls-server-name="vault-2" -ca-cert="$(pwd)/config/vault-2/ca.crt"

# Initialize Vault servers
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TLS_SERVER_NAME="vault-0"
export VAULT_CACERT="$(pwd)/config/vault-0/ca.crt"

vault operator init -key-shares=1 -key-threshold=1



UNSEAL_KEY=UNSEAL_KEY
ROOT_TOKEN=ROOT_TOKEN

vault operator unseal "$UNSEAL_KEY"

export VAULT_ADDR="https://127.0.0.1:8210"
export VAULT_TLS_SERVER_NAME="vault-1"
export VAULT_CACERT="$(pwd)/config/vault-1/ca.crt"

vault status
vault operator unseal "$UNSEAL_KEY"

export VAULT_ADDR="https://127.0.0.1:8220"
export VAULT_TLS_SERVER_NAME="vault-2"
export VAULT_CACERT="$(pwd)/config/vault-2/ca.crt"

vault status
vault operator unseal "$UNSEAL_KEY"


vault login "$ROOT_TOKEN"
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

# Clean up operations - stopping containers, removing network, and cleaning directories
docker container stop vault-0 vault-2
docker container rm vault-0 vault-1 vault-2
docker network rm vault-network

# Clean up the data directories
rm -rf "$(pwd)/data"
rm -rf "$(pwd)/config/vault-0"
rm -rf "$(pwd)/config/vault-1"
rm -rf "$(pwd)/config/vault-2"
rm -rf "$(pwd)/certificates"
