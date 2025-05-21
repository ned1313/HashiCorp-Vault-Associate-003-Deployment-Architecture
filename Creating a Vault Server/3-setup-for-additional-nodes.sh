#!/bin/bash
# Script to set up additional Vault nodes with TLS certificates and configuration

# Create directories for configuration and data storage
echo "Creating directories for configuration and data storage..."
mkdir -p data/vault-1
mkdir -p config/vault-1
mkdir -p data/vault-2
mkdir -p config/vault-2

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
    echo "Error: OpenSSL not found. Please install OpenSSL before running this script."
    exit 1
fi

# Generate certificates
echo "Generating certificates for the additional servers..."

# Create working directory for certificates
cd certificates || { echo "Error: certificates directory not found. Run 1-setup-directories-and-certificates.sh first."; exit 1; }

# Generate vault-1 and vault-2 key and CSR
echo "Generating keys and certificate signing requests..."
openssl genrsa -out vault-1.key 2048
openssl req -new -key vault-1.key -out vault-1.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-1"

openssl genrsa -out vault-2.key 2048
openssl req -new -key vault-2.key -out vault-2.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-2"

# Create config file for SAN for vault-1 and vault-2
echo "Creating certificate extension files..."
cat > vault-1.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-1
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

cat > vault-2.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-2
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# Sign the vault-1 and vault-2 certificates
echo "Signing certificates..."
openssl x509 -req -in vault-1.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out vault-1.crt -days 825 -sha256 -extfile vault-1.ext

openssl x509 -req -in vault-2.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out vault-2.crt -days 825 -sha256 -extfile vault-2.ext

# Copy certificates to config directory
echo "Copying certificates to config directories..."
cp ca.crt ../config/vault-1/
cp vault-1.crt ../config/vault-1/tls.crt
cp vault-1.key ../config/vault-1/tls.key
cp ca.crt ../config/vault-2/
cp vault-2.crt ../config/vault-2/tls.crt
cp vault-2.key ../config/vault-2/tls.key

# Set appropriate permissions for Docker (similar to 2-deploy-vault.sh)
chmod 644 ../config/vault-1/ca.crt ../config/vault-1/tls.crt
chmod 600 ../config/vault-1/tls.key
chmod 644 ../config/vault-2/ca.crt ../config/vault-2/tls.crt
chmod 600 ../config/vault-2/tls.key

# Copy Config file to config directory
echo "Copying configuration files..."
cp ../config/vault-1.hcl ../config/vault-1/
cp ../config/vault-2.hcl ../config/vault-2/

# Return to original directory
cd ..

echo "Setup complete for additional Vault nodes!"
echo "You can now run 4-add-servers-to-cluster.sh to add these nodes to your Vault cluster."
