#!/usr/bin/env bash
# Item Server — Base setup for Debian 12
# Run as root: sudo ./01-base-setup.sh

set -euo pipefail

echo "=== Item Server: Base Setup ==="

# Update system
echo "[1/5] Updating system..."
apt update && apt upgrade -y

# Install essential packages
echo "[2/5] Installing base packages..."
apt install -y \
  curl \
  wget \
  git \
  htop \
  ufw \
  unattended-upgrades \
  apt-listchanges \
  rsync \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  sudo

# Configure firewall
echo "[3/5] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8000/tcp  # Coolify UI
ufw --force enable

# Harden SSH
echo "[4/5] Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable password auth (ensure you have SSH key access first!)
# Uncomment the lines below AFTER you have confirmed key-based login works:
# sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

systemctl restart sshd

# Enable automatic security updates
echo "[5/5] Enabling automatic security updates..."
dpkg-reconfigure -plow unattended-upgrades

echo ""
echo "=== Base setup complete ==="
echo "Next: Run 02-install-coolify.sh"
