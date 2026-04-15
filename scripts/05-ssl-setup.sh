#!/usr/bin/env bash
# Item Server — Setup wildcard SSL for *.item.intern
# Generates certs, configures Traefik, and moves Coolify UI to https://coolify.item.intern
# Run as root: sudo ./05-ssl-setup.sh

set -euo pipefail

MKCERT_VERSION="v1.4.4"
CERT_DIR="/data/coolify/proxy/certs"
TRAEFIK_CONTAINER="coolify-proxy"
# Traefik mounts /data/coolify/proxy as /traefik inside the container
TRAEFIK_CERT_DIR="/traefik/certs"

echo "=== Item Server: SSL Setup ==="

# Check that Coolify is installed
if [ ! -d "/data/coolify/proxy" ]; then
  echo "ERROR: /data/coolify/proxy not found — run 02-install-coolify.sh first"
  exit 1
fi

# Install mkcert dependencies
echo "[1/8] Installing dependencies..."
apt install -y libnss3-tools wget

# Install mkcert
echo "[2/8] Installing mkcert..."
wget -q "https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-amd64" \
  -O /usr/local/bin/mkcert
chmod +x /usr/local/bin/mkcert

# Create local CA
echo "[3/8] Creating local Certificate Authority..."
CAROOT=/opt/ssl/ca mkcert -install

# Generate wildcard cert — store inside Traefik's mounted volume
echo "[4/8] Generating wildcard cert for *.item.intern..."
mkdir -p "${CERT_DIR}"
CAROOT=/opt/ssl/ca mkcert \
  -cert-file "${CERT_DIR}/item-intern.pem" \
  -key-file "${CERT_DIR}/item-intern-key.pem" \
  "*.item.intern" \
  "item.intern"

chmod 600 "${CERT_DIR}/item-intern-key.pem"

# Write Traefik TLS config
echo "[5/8] Writing Traefik TLS config..."
cat > /data/coolify/proxy/dynamic/certificates.yml << EOF
tls:
  certificates:
    - certFile: ${TRAEFIK_CERT_DIR}/item-intern.pem
      keyFile: ${TRAEFIK_CERT_DIR}/item-intern-key.pem
  stores:
    default:
      defaultCertificate:
        certFile: ${TRAEFIK_CERT_DIR}/item-intern.pem
        keyFile: ${TRAEFIK_CERT_DIR}/item-intern-key.pem
EOF

# Route Coolify UI through Traefik at https://coolify.item.intern
echo "[6/8] Adding Traefik route for Coolify UI..."
cat > /data/coolify/proxy/dynamic/coolify-ui.yml << EOF
http:
  routers:
    coolify-ui:
      rule: "Host(\`coolify.item.intern\`)"
      entrypoints:
        - https
      service: coolify-ui
      tls: {}
    coolify-ui-http:
      rule: "Host(\`coolify.item.intern\`)"
      entrypoints:
        - http
      middlewares:
        - coolify-redirect-https
      service: coolify-ui
  middlewares:
    coolify-redirect-https:
      redirectScheme:
        scheme: https
        permanent: true
  services:
    coolify-ui:
      loadBalancer:
        servers:
          - url: "http://coolify:8080"
EOF

# Bind Coolify's port 8000 to localhost only (no external access)
echo "[7/8] Restricting Coolify port 8000 to localhost..."
COMPOSE_FILE="/data/coolify/source/docker-compose.prod.yml"
if grep -q '${APP_PORT:-8000}:8080' "${COMPOSE_FILE}"; then
  sed -i 's/"${APP_PORT:-8000}:8080"/"127.0.0.1:8000:8080"/' "${COMPOSE_FILE}"
fi

# Restart Traefik and Coolify
echo "[8/8] Restarting Traefik and Coolify..."
docker restart "${TRAEFIK_CONTAINER}"
cd /data/coolify/source && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d coolify

echo ""
echo "=== SSL setup complete ==="
echo ""
echo "Wildcard cert:  *.item.intern (expires in 2+ years)"
echo "Cert file:      ${CERT_DIR}/item-intern.pem"
echo "Key file:       ${CERT_DIR}/item-intern-key.pem"
echo "CA root cert:   /opt/ssl/ca/rootCA.pem"
echo ""
echo "Coolify UI:     https://coolify.item.intern"
echo "Port 8000:      localhost only (not reachable from network)"
echo ""
echo "To trust the cert on team machines, distribute the CA:"
echo "  scp eric@192.168.50.150:/opt/ssl/ca/rootCA.pem ."
echo ""
echo "  macOS:   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem"
echo "  Linux:   sudo cp rootCA.pem /usr/local/share/ca-certificates/item-intern-ca.crt && sudo update-ca-certificates"
echo "  Windows: certutil -addstore -f 'ROOT' rootCA.pem"
