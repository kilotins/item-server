#!/usr/bin/env bash
# Item Server — Setup internal DNS with dnsmasq
# Run as root: sudo ./03-dns-setup.sh

set -euo pipefail

SERVER_IP="${1:-$(hostname -I | awk '{print $1}')}"

echo "=== Item Server: DNS Setup ==="
echo "Server IP: ${SERVER_IP}"

# Install dnsmasq
echo "[1/3] Installing dnsmasq..."
apt install -y dnsmasq

# Configure wildcard DNS
echo "[2/3] Configuring *.item.intern -> ${SERVER_IP}..."
cat > /etc/dnsmasq.d/item-intern.conf << EOF
# Item Consulting internal DNS
# All *.item.intern resolves to this server
address=/item.intern/${SERVER_IP}
EOF

# Restart dnsmasq
echo "[3/3] Restarting dnsmasq..."
systemctl restart dnsmasq
systemctl enable dnsmasq

echo ""
echo "=== DNS setup complete ==="
echo "All *.item.intern now resolves to ${SERVER_IP}"
echo ""
echo "To use from other machines, set DNS server to ${SERVER_IP}"
echo "Or add to each machine's /etc/hosts:"
echo "  ${SERVER_IP}  coolify.item.intern"
echo "  ${SERVER_IP}  logpilot.item.intern"
echo "  ${SERVER_IP}  opensearch.item.intern"
