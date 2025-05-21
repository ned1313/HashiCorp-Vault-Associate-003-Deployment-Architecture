# PowerShell script to set up directory structure and generate TLS certificates for Vault server
# Run this script from the Creating a Vault Server directory

# Create directories for configuration and data storage
New-Item -ItemType Directory -Path "data\vault-1" -Force
New-Item -ItemType Directory -Path "config\vault-1" -Force
New-Item -ItemType Directory -Path "data\vault-2" -Force
New-Item -ItemType Directory -Path "config\vault-2" -Force

# Check if OpenSSL is available
if (-not (Get-Command "openssl" -ErrorAction SilentlyContinue)) {
    Write-Error "OpenSSL not found. Please install OpenSSL or use Windows Subsystem for Linux (WSL) to run the bash version of this script."
    exit 1
}

# Generate certificates
Write-Host "Generating certificates for the additional servers..."

# Create working directory for certificates
Set-Location -Path "certificates"

# Generate vault-1 and vault-2 key and CSR
& openssl genrsa -out vault-1.key 2048
& openssl req -new -key vault-1.key -out vault-1.csr `
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-1"

& openssl genrsa -out vault-2.key 2048
& openssl req -new -key vault-2.key -out vault-2.csr `
  -subj "/C=US/ST=State/L=City/O=Organization/CN=vault-2"


# Create config file for SAN for vault-1 and vault-2
@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-1
DNS.2 = localhost
IP.1 = 127.0.0.1
"@ | Out-File -FilePath "vault-1.ext" -Encoding ascii

@"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = vault-2
DNS.2 = localhost
IP.1 = 127.0.0.1
"@ | Out-File -FilePath "vault-2.ext" -Encoding ascii

# Sign the vault-1 and vault-2 certificates
& openssl x509 -req -in vault-1.csr -CA ca.crt -CAkey ca.key -CAcreateserial `
  -out vault-1.crt -days 825 -sha256 -extfile vault-1.ext

& openssl x509 -req -in vault-2.csr -CA ca.crt -CAkey ca.key -CAcreateserial `
  -out vault-2.crt -days 825 -sha256 -extfile vault-2.ext

# Copy certificates to config directory
Copy-Item -Path "ca.crt" -Destination "..\config\vault-1\"
Copy-Item -Path "vault-1.crt" -Destination "..\config\vault-1\tls.crt"
Copy-Item -Path "vault-1.key" -Destination "..\config\vault-1\tls.key"
Copy-Item -Path "ca.crt" -Destination "..\config\vault-2\"
Copy-Item -Path "vault-2.crt" -Destination "..\config\vault-2\tls.crt"
Copy-Item -Path "vault-2.key" -Destination "..\config\vault-2\tls.key"

# Copy Config file to config directory
Copy-Item -Path "..\config\vault-1.hcl" -Destination "..\config\vault-1\"
Copy-Item -Path "..\config\vault-2.hcl" -Destination "..\config\vault-2\"

Set-Location -Path ".."

Write-Host "Setup complete!"