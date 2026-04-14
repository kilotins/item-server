#!/usr/bin/env bash
# Item Server — Setup wildcard SSL for *.item.intern
# Run as root: sudo ./05-ssl-setup.sh

set -euo pipefail

echo "=== Item Server: SSL Setup ==="

# Install mkcert dependencies
echo "[1/5] Installing dependencies..."
apt install -y libnss3-tools wget

# Install mkcert
echo "[2/5] Installing mkcert..."
MKCERT_VERSION="v1.4.4"
wget -q "https://dl.filippo.io/mkcert/latest?for=linux/amd64" -O /usr/local/bin/mkcert
chmod +x /usr/local/bin/mkcert

# Create local CA
echo "[3/5] Creating local Certificate Authority..."
CAROOT=/opt/ssl/ca mkcert -install

# Generate wildcard cert
echo "[4/5] Generating wildcard cert for *.item.intern..."
mkdir -p /opt/ssl/certs
CAROOT=/opt/ssl/ca mkcert \
  -cert-file /opt/ssl/certs/item-intern.pem \
  -key-file /opt/ssl/certs/item-intern-key.pem \
  "*.item.intern" \
  "item.intern"

chmod 600 /opt/ssl/certs/item-intern-key.pem

# Configure Coolify's Traefik to use the wildcard cert
echo "[5/5] Configuring Traefik..."
mkdir -p /data/coolify/proxy

# Dynamic config — tell Traefik about the cert
cat > /data/coolify/proxy/dynamic-conf.yml << EOF
tls:
  certificates:
    - certFile: /opt/ssl/certs/item-intern.pem
      keyFile: /opt/ssl/certs/item-intern-key.pem
  stores:
    default:
      defaultCertificate:
        certFile: /opt/ssl/certs/item-intern.pem
        keyFile: /opt/ssl/certs/item-intern-key.pem
EOF

echo ""
echo "=== SSL setup complete ==="
echo ""
echo "Wildcard cert:  *.item.intern"
echo "Cert file:      /opt/ssl/certs/item-intern.pem"
echo "Key file:       /opt/ssl/certs/item-intern-key.pem"
echo "CA root cert:   /opt/ssl/ca/rootCA.pem"
echo ""
echo "To trust the cert on team machines, distribute the CA:"
echo "  scp root@item-server:/opt/ssl/ca/rootCA.pem ."
echo ""
echo "  macOS:   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem"
echo "  Linux:   sudo cp rootCA.pem /usr/local/share/ca-certificates/item-intern-ca.crt && sudo update-ca-certificates"
echo "  Windows: certutil -addstore -f 'ROOT' rootCA.pem"
