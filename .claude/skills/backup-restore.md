# Backup & Restore — Item Server

## Vad ska backas upp

| Data | Plats | Kritiskt |
|------|-------|----------|
| OpenSearch-index | Docker volume `opensearch-data` | Ja — kundedata |
| Coolify-config | `/data/coolify/` | Ja — alla app-konfigurationer |
| Docker volumes | Varierar per app | Beror på appen |
| SSL-cert + CA | `/opt/ssl/` | Ja — annars måste CA distribueras om |
| Skript + config | Git repo | Nej — finns i GitHub |

## Backup-strategi

### Daglig backup (cron)
```bash
#!/bin/bash
# /usr/local/sbin/backup.sh
set -euo pipefail

BACKUP_DIR="/backup"
DATE=$(date +%Y-%m-%d)
RETAIN_DAYS=14

mkdir -p "${BACKUP_DIR}/${DATE}"

# 1. Coolify-konfiguration
echo "[1/3] Backing up Coolify config..."
tar czf "${BACKUP_DIR}/${DATE}/coolify-config.tar.gz" /data/coolify/

# 2. Docker volumes
echo "[2/3] Backing up Docker volumes..."
for vol in $(docker volume ls -q); do
  docker run --rm \
    -v "${vol}":/data:ro \
    -v "${BACKUP_DIR}/${DATE}":/backup \
    alpine tar czf "/backup/volume-${vol}.tar.gz" /data
done

# 3. SSL-cert och CA
echo "[3/3] Backing up SSL..."
tar czf "${BACKUP_DIR}/${DATE}/ssl.tar.gz" /opt/ssl/

# Rensa gamla backups
find "${BACKUP_DIR}" -maxdepth 1 -type d -mtime +${RETAIN_DAYS} -exec rm -rf {} +

echo "Backup complete: ${BACKUP_DIR}/${DATE}"
```

### Cron-jobb
```bash
# /etc/cron.d/item-backup
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 3 * * * root /usr/local/sbin/backup.sh >> /var/log/backup.log 2>&1
```

## OpenSearch Snapshot (bättre för stora index)

### Registrera snapshot-repo
```bash
curl -X PUT "https://localhost:9200/_snapshot/backup" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/snapshots",
      "compress": true
    }
  }'
```

### Ta snapshot
```bash
# Alla index
curl -X PUT "https://localhost:9200/_snapshot/backup/snapshot-$(date +%Y%m%d)" \
  -u admin:password --insecure

# Status
curl -X GET "https://localhost:9200/_snapshot/backup/_all" \
  -u admin:password --insecure
```

### Docker Compose — lägg till snapshot-volym
```yaml
# Lägg till i opensearch-tjänsten:
volumes:
  - opensearch-data:/usr/share/opensearch/data
  - /backup/opensearch-snapshots:/snapshots
```

## Restore

### Coolify-konfiguration
```bash
# Stoppa Coolify
systemctl stop coolify

# Återställ
tar xzf /backup/2026-04-14/coolify-config.tar.gz -C /

# Starta Coolify
systemctl start coolify
```

### Docker volume
```bash
# Återskapa en specifik volym
docker volume create my-volume
docker run --rm \
  -v my-volume:/data \
  -v /backup/2026-04-14:/backup:ro \
  alpine tar xzf /backup/volume-my-volume.tar.gz -C /
```

### OpenSearch snapshot restore
```bash
# Stäng index först
curl -X POST "https://localhost:9200/index-name/_close" \
  -u admin:password --insecure

# Återställ
curl -X POST "https://localhost:9200/_snapshot/backup/snapshot-20260414/_restore" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{"indices": "index-name"}'
```

### Fullständig disaster recovery
```bash
# 1. Installera Debian + kör skripten (01-06)
# 2. Återställ SSL-cert
tar xzf /backup/DATUM/ssl.tar.gz -C /
# 3. Återställ Coolify-config
tar xzf /backup/DATUM/coolify-config.tar.gz -C /
systemctl restart coolify
# 4. Återställ Docker volumes
# 5. Starta alla tjänster via Coolify UI
```

## Offsite backup

### Rsync till annan maskin
```bash
# Lägg till i backup.sh eller kör separat
rsync -az --delete /backup/ eric@offsite-server:/backup/item-server/
```

### Rclone till molnlagring
```bash
# S3-kompatibel (Backblaze B2, Wasabi, etc)
rclone sync /backup remote:item-server-backup --transfers 4
```

## Verifiera backup

```bash
# Testa restore av en volym till temporär plats
docker run --rm \
  -v /backup/2026-04-14:/backup:ro \
  alpine tar tzf /backup/volume-opensearch-data.tar.gz | head

# Kontrollera storlek
du -sh /backup/*
```
