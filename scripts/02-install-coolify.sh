#!/usr/bin/env bash
# Item Server — Install Coolify
# Run as root: sudo ./02-install-coolify.sh

set -euo pipefail

echo "=== Item Server: Install Coolify ==="

# Coolify handles Docker installation automatically
echo "[1/1] Installing Coolify (includes Docker)..."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo ""
echo "=== Coolify installed ==="
echo "Access Coolify UI at: http://<server-ip>:8000"
echo "Create your admin account on first visit."
echo ""
echo "Next steps in Coolify UI:"
echo "  1. Create Teams: logpilot, enonic, sandbox"
echo "  2. Add team members"
echo "  3. Configure domains"
echo ""
echo "Next script: Run 03-dns-setup.sh"
