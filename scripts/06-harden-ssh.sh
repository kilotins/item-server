#!/usr/bin/env bash
# Item Server — Final SSH hardening
# Run LAST after all other scripts are done and key-based login is confirmed.
# Run as root: sudo ./06-harden-ssh.sh
#
# WARNING: After this script, SSH is only available on port 10022.
#          Make sure you have key-based login working before running!

set -euo pipefail

echo "=== Item Server: SSH Hardening (final step) ==="

# Copy hardened sshd_config
echo "[1/4] Installing hardened sshd_config (port 10022)..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.pre-harden
cp configs/sshd_config /etc/ssh/sshd_config

# Update firewall — open 10022, close 22
echo "[2/4] Updating firewall rules..."
ufw allow 10022/tcp
ufw delete allow 22/tcp

# Update fail2ban
echo "[3/4] Updating fail2ban for port 10022..."
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 10022
maxretry = 5
bantime = 3600
findtime = 600
EOF
systemctl restart fail2ban

# Restart SSH on new port
echo "[4/4] Restarting SSH on port 10022..."
systemctl restart sshd

echo ""
echo "=== SSH hardening complete ==="
echo ""
echo "SSH is now on port 10022 with key-only auth."
echo "Reconnect with:"
echo "  ssh -p 10022 eric@item-server.item.intern"
