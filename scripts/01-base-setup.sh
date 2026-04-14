#!/usr/bin/env bash
# Item Server — Base setup for Debian 12
# Run as root: sudo ./01-base-setup.sh

set -euo pipefail

echo "=== Item Server: Base Setup ==="

# System identity
echo "[1/9] Setting hostname..."
hostnamectl set-hostname item-server

# Timezone
echo "[2/9] Setting timezone to Europe/Oslo..."
timedatectl set-timezone Europe/Oslo

# Locale
echo "[3/9] Setting locale to en_US.UTF-8..."
apt install -y locales
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Create item group
echo "[4/10] Creating 'item' group..."
groupadd -f item
usermod -aG item eric

# Update system
echo "[5/10] Updating system..."
apt update && apt upgrade -y

# Install essential packages
echo "[6/10] Installing base packages..."
apt install -y \
  curl \
  wget \
  git \
  htop \
  ufw \
  fail2ban \
  unattended-upgrades \
  apt-listchanges \
  rsync \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  sudo

# NTP — ensure clock is synced
echo "[7/10] Enabling NTP time sync..."
timedatectl set-ntp true

# Configure firewall
echo "[8/10] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH (moved to 10022 in 06-harden-ssh.sh)
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8000/tcp  # Coolify UI
ufw --force enable

# Harden SSH
echo "[9/10] Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable password auth (ensure you have SSH key access first!)
# Uncomment the lines below AFTER you have confirmed key-based login works:
# sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Configure fail2ban for SSH brute force protection
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 22
maxretry = 5
bantime = 3600
findtime = 600
EOF
systemctl enable fail2ban
systemctl restart fail2ban

systemctl restart sshd

# Swap — safety net for OpenSearch memory pressure
echo "[10/10] Setting up swap..."
if [ ! -f /swapfile ]; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Enable automatic security updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
echo 'Unattended-Upgrade::Automatic-Reboot "false";' > /etc/apt/apt.conf.d/50unattended-upgrades-local

echo ""
echo "=== Base setup complete ==="
echo ""
echo "Hostname:  item-server"
echo "Timezone:  Europe/Oslo"
echo "Locale:    en_US.UTF-8"
echo "Group:     item (eric added)"
echo "Firewall:  22, 80, 443, 8000"
echo "Fail2ban:  SSH protection active"
echo "Swap:      4 GB"
echo "NTP:       enabled"
echo ""
echo "TODO (manual):"
echo "  - Configure static IP in /etc/network/interfaces or DHCP reservation"
echo "  - BIOS: Power On with AC, Lid Close = do nothing"
echo ""
echo "Next: Run 02-install-coolify.sh"
echo "Last: Run 06-harden-ssh.sh (moves SSH to port 10022)"
