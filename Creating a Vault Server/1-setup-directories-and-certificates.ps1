# PowerShell script to set up directory structure and generate TLS certificates for Vault server

# Create directories for configuration and data storage
New-Item -ItemType Directory -Path "data\vault-0" -Force
New-Item -ItemType Directory -Path "config\vault-0" -Force

# Check if OpenSSL is available
if (-not (Get-Command "openssl" -ErrorAction SilentlyContinue)) {
    Write-Error "OpenSSL not found. Please install OpenSSL or use Windows Subsystem for Linux (WSL) to run the bash version of this script."
    exit 1
}

# Generate certificates
Write-Host "Generating certificates..."

# Create working directory for certificates
New-Item -ItemType Directory -Path "certificates" -Force
Set-Location -Path "certificates"

# Generate root CA key and certificate
& openssl genrsa -out ca.key 2048
& openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt `
  -subj "/C=US/ST=State/L=City/O=Organization/CN=Vault CA"

# Generate vault-0 key and CSR
& openssl genrsa -out vault-0.key 2048
& openssl req -new -key vault-0.key -out vault-0.csr `
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-0"

# Create config file for SAN
@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-0
DNS.2 = localhost
IP.1 = 127.0.0.1
"@ | Out-File -FilePath "vault-0.ext" -Encoding ascii

# Sign the vault-0 certificate
& openssl x509 -req -in vault-0.csr -CA ca.crt -CAkey ca.key -CAcreateserial `
  -out vault-0.crt -days 825 -sha256 -extfile vault-0.ext

# Copy certificates to config directory
Copy-Item -Path "ca.crt" -Destination "..\config\vault-0\"
Copy-Item -Path "vault-0.crt" -Destination "..\config\vault-0\tls.crt"
Copy-Item -Path "vault-0.key" -Destination "..\config\vault-0\tls.key"

# Copy Config file to config directory
Copy-Item -Path "..\config\vault-config.hcl" -Destination "..\config\vault-0\"

Write-Host "Certificates generated and placed in config\vault-0\"
Set-Location -Path ".."

Write-Host "Setup complete!"