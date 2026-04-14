#!/usr/bin/env bash
# Item Server — Prepare host for OpenSearch
# Run as root: sudo ./04-opensearch.sh

set -euo pipefail

echo "=== Item Server: OpenSearch Preparation ==="

# Set vm.max_map_count (required by OpenSearch)
echo "[1/2] Setting vm.max_map_count=262144..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# Create data directory
echo "[2/2] Creating OpenSearch data directory..."
mkdir -p /opt/opensearch-data
chmod 777 /opt/opensearch-data

echo ""
echo "=== OpenSearch host preparation complete ==="
echo ""
echo "Deploy the OpenSearch stack via Coolify:"
echo "  1. Create new project in Coolify (team: enonic)"
echo "  2. Add Docker Compose service"
echo "  3. Paste contents of compose/opensearch/docker-compose.yml"
echo "  4. Deploy"
echo ""
echo "Or deploy manually:"
echo "  cd compose/opensearch && docker compose up -d"
