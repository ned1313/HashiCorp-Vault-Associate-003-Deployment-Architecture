#!/bin/bash
# Script to set up directory structure and generate TLS certificates for Vault server

# Create directories for configuration and data storage
mkdir -p data/vault-0
mkdir -p config/vault-0

# Generate certificates
echo "Generating certificates..."

# Create working directory for certificates
mkdir -p certificates
cd certificates

# Generate root CA key and certificate
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Vault CA"

# Generate vault-0 key and CSR
openssl genrsa -out vault-0.key 2048
openssl req -new -key vault-0.key -out vault-0.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-0"

# Create config file for SAN
cat > vault-0.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-0
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# Sign the vault-0 certificate
openssl x509 -req -in vault-0.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out vault-0.crt -days 825 -sha256 -extfile vault-0.ext

# Copy certificates to config directory
cp ca.crt ../config/vault-0/
cp vault-0.crt ../config/vault-0/tls.crt
cp vault-0.key ../config/vault-0/tls.key

echo "Certificates generated and placed in config/vault-0/"
cd ..

echo "Setup complete!"