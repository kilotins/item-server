#!/usr/bin/env bash
# Item Server — Base setup for Debian 12
# Run as root: sudo ./01-base-setup.sh

set -euo pipefail

echo "=== Item Server: Base Setup ==="

# System identity
echo "[1/12] Setting hostname..."
hostnamectl set-hostname itemserver

# Timezone
echo "[2/12] Setting timezone to Europe/Oslo..."
timedatectl set-timezone Europe/Oslo

# Locale
echo "[3/12] Setting locale to en_US.UTF-8..."
apt install -y locales
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/default/locale

# Create item group
echo "[4/12] Creating 'item' group..."
groupadd -f item
usermod -aG item eric

# Update system
echo "[5/12] Updating system..."
apt update && apt upgrade -y

# Install essential packages
echo "[6/12] Installing base packages..."
apt install -y \
  curl \
  wget \
  git \
  htop \
  nmon \
  sysstat \
  ufw \
  fail2ban \
  unattended-upgrades \
  apt-listchanges \
  rsync \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  linuxlogo \
  tmux \
  ncdu \
  dnsutils \
  iotop \
  bash-completion \
  sudo

# NTP — ensure clock is synced
echo "[7/12] Enabling NTP time sync..."
timedatectl set-ntp true

# Configure firewall
echo "[8/12] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH (moved to 10022 in 06-harden-ssh.sh)
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8000/tcp  # Coolify UI
ufw --force enable

# Harden SSH
echo "[9/12] Hardening SSH..."
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

# Enable sysstat (sar) for performance monitoring
echo "[10/12] Enabling sysstat..."
sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
systemctl enable sysstat
systemctl restart sysstat

# Login banner
echo "[11/12] Setting up login banner..."
cat > /usr/local/sbin/update-motd.sh << 'SCRIPT'
#!/bin/sh
OUTPUT="/etc/motd"
{
  /usr/bin/linux_logo -u -y 2>/dev/null || echo "=== Item Server ==="
  echo ""
  echo "  Hostname: $(hostname)"
  echo "  Uptime:  $(uptime -p)"
  echo "  Load:    $(cut -d' ' -f1-3 /proc/loadavg)"
  echo "  Memory:  $(free -h | awk '/Mem:/{print $3 "/" $2}')"
  echo "  Disk:    $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')"
  echo ""
} > "$OUTPUT"
SCRIPT
chmod +x /usr/local/sbin/update-motd.sh
/usr/local/sbin/update-motd.sh
cat > /etc/cron.d/update-motd << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * root /usr/local/sbin/update-motd.sh
EOF

# Enable automatic security updates
echo "[12/12] Enabling automatic security updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
echo 'Unattended-Upgrade::Automatic-Reboot "false";' > /etc/apt/apt.conf.d/50unattended-upgrades-local

echo ""
echo "=== Base setup complete ==="
echo ""
echo "Hostname:  itemserver"
echo "Timezone:  Europe/Oslo"
echo "Locale:    en_US.UTF-8"
echo "Group:     item (eric added)"
echo "Firewall:  22, 80, 443, 8000"
echo "Fail2ban:  SSH protection active"
echo "NTP:       enabled"
echo "Sysstat:   enabled (sar)"
echo "nmon:      installed"
echo "Banner:    motd updates every 5 min"
echo ""
echo "TODO (manual):"
echo "  - Configure static IP in /etc/network/interfaces or DHCP reservation"
echo "  - BIOS: Power On with AC, Lid Close = do nothing"
echo ""
echo "Next: Run 02-install-coolify.sh"
echo "Last: Run 06-harden-ssh.sh (moves SSH to port 10022)"
