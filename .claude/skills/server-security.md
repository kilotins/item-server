# Server Security — Debian 12 + Coolify

## Threat Model

Intern dev-server på kontoret som kan exponeras externt via Cloudflare Tunnel.
Ikke produksjonsserver, men kjører kundedemoer (OpenSearch) og teamets prosjekter.

**Angrepsvektorer å beskytte mot:**
- Uautorisert SSH-tilgang
- Containerutbrudd (sandbox → logpilot)
- Eksponerte tjenester uten autentisering
- Utdatert programvare med kjente sårbarheter
- Lekkasje av credentials/API-nøkler
- DDoS mot eksponerte endepunkter

## SSH-herding

### Obligatorisk
- Nøkkelbasert autentisering (disable password auth)
- `PermitRootLogin no`
- `MaxAuthTries 3`
- Bruk `fail2ban` for brute-force-beskyttelse

### Oppsett
```bash
# Installer fail2ban
sudo apt install -y fail2ban

# Konfigurer for SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = 10022
filter = sshd
maxretry = 3
bantime = 3600
findtime = 600
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# Sjekk bannede IP-er
sudo fail2ban-client status sshd
```

### SSH-nøkler
```bash
# På klient (Mac/Linux):
ssh-keygen -t ed25519 -C "eric@item.no"
ssh-copy-id -i ~/.ssh/id_ed25519.pub eric@<server-ip>

# Deretter disable password auth:
# PasswordAuthentication no i /etc/ssh/sshd_config
```

## Brannmur (ufw)

### Minimale porter
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 10022/tcp  # SSH
sudo ufw allow 80/tcp     # HTTP (Coolify/Traefik)
sudo ufw allow 443/tcp    # HTTPS (Coolify/Traefik)
sudo ufw allow 8000/tcp   # Coolify UI (vurder å begrense til intern IP)
sudo ufw enable
```

### Begrens Coolify UI til internt nett
```bash
# Fjern åpen 8000 og begrens til lokalt nett:
sudo ufw delete allow 8000/tcp
sudo ufw allow from 192.168.1.0/24 to any port 8000
```

### Sjekk status
```bash
sudo ufw status verbose
```

## Docker-sikkerhet

### Container-isolering
- Kjør containere som non-root bruker der mulig
- Bruk `read_only: true` i compose der det passer
- Sett minnegrenser per container for å unngå OOM
- Ikke bruk `--privileged` med mindre nødvendig
- Begrens capabilities: `cap_drop: [ALL]`, legg til kun det som trengs

### Nettverk
- Bruk separate Docker-nettverk per sone (logpilot, enonic, sandbox)
- Ikke eksponer porter direkte — la Traefik/Coolify håndtere routing
- Unngå `network_mode: host`

### Images
- Bruk spesifikke versjon-tags, ikke `latest`
- Foretrekk offisielle images
- Skann images: `docker scout cves <image>`

### Eksempel compose med sikkerhet
```yaml
services:
  app:
    image: myapp:1.2.3
    read_only: true
    user: "1000:1000"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"
    tmpfs:
      - /tmp
```

## Credentials og hemmeligheter

### Regler
- Aldri commit `.env`-filer med ekte credentials
- Bruk Coolify sine environment variables (krypterte)
- API-nøkler lagres i Coolify, IKKE i compose-filer
- Bruk `.env.example` med plassholdere i git

### Sjekk for lekkede hemmeligheter
```bash
# Søk etter mulige lekkasjer i repo
grep -rn "password\|secret\|api_key\|token" --include="*.yml" --include="*.sh" --include="*.conf" .
```

## Ekstern tilgang (Cloudflare Tunnel)

### Hvorfor Cloudflare Tunnel
- Ingen åpne porter i brannmuren
- DDoS-beskyttelse inkludert
- SSL/TLS automatisk
- Zero Trust access policies

### Sikkerhetsprinsipper
- Eksponer KUN spesifikke tjenester, ikke hele serveren
- Bruk Cloudflare Access for autentisering på sensitive tjenester
- Aldri eksponer Coolify UI eksternt uten autentisering
- OpenSearch Dashboards bak Cloudflare Access (e-post/SSO)

### Oppsett
```bash
# Installer cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Autentiser
cloudflared tunnel login

# Opprett tunnel
cloudflared tunnel create item-dev

# Konfigurer (eksempel)
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <tunnel-id>
credentials-file: /home/eric/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: logpilot.dev.item.no
    service: http://localhost:8080
  - hostname: opensearch.dev.item.no
    service: http://localhost:5601
  # Catch-all: return 404
  - service: http_status:404
EOF

# Kjør som systemd-tjeneste
sudo cloudflared service install
```

## Automatiske oppdateringer

```bash
# Allerede satt opp via 01-base-setup.sh
# Sjekk status:
sudo systemctl status unattended-upgrades

# Se logg:
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

## Overvåking og logging

### Grunnleggende sjekker
```bash
# Hvem er logget inn
who

# Mislykkede innloggingsforsøk
sudo journalctl -u sshd | grep "Failed"

# Diskbruk
df -h

# Minnebruk
free -h

# Docker-containerbruk
docker stats --no-stream

# Åpne porter
sudo ss -tlnp
```

### Logrotate
Docker-logger kan vokse ukontrollert. Sett global loggrense:
```bash
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
sudo systemctl restart docker
```

## Backup-sikkerhet

```bash
# Backup-script med kryptering
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y-%m-%d)

# Docker volumes
docker run --rm -v opensearch-data:/data -v ${BACKUP_DIR}:/backup \
  alpine tar czf /backup/opensearch-${DATE}.tar.gz /data

# Krypter backup
gpg --symmetric --cipher-algo AES256 ${BACKUP_DIR}/opensearch-${DATE}.tar.gz
rm ${BACKUP_DIR}/opensearch-${DATE}.tar.gz

# Behold kun siste 7 dager
find ${BACKUP_DIR} -name "*.gpg" -mtime +7 -delete
```

## Sikkerhetsjekkliste

### Ved oppsett
- [ ] SSH nøkkelbasert, password disabled
- [ ] fail2ban aktiv
- [ ] Brannmur (ufw) aktivert med minimale porter
- [ ] Coolify UI begrenset til internt nett
- [ ] Automatiske sikkerhetsoppdateringer aktivert
- [ ] Docker log rotation konfigurert
- [ ] .env-filer i .gitignore

### Ukentlig
- [ ] Sjekk fail2ban-logg for angrep
- [ ] Sjekk diskbruk (OpenSearch vokser)
- [ ] Verifiser at backups kjører
- [ ] Se over Docker-containere (kjører noe uventet?)

### Månedlig
- [ ] Oppdater Docker-images til nyeste patch
- [ ] Gjennomgå Cloudflare Tunnel-konfigurasjon
- [ ] Sjekk for kjente sårbarheter: `docker scout cves`
- [ ] Roter credentials som bør roteres
- [ ] Gjennomgå SSH authorized_keys (fjern gamle)

## Ved sikkerhetshendelse

1. **Isoler** — koble fra nett om nødvendig
2. **Dokumenter** — hva skjedde, når, hva er påvirket
3. **Sjekk** — loggfiler, `last`, `who`, `journalctl`
4. **Fiks** — patch, roter credentials, oppdater regler
5. **Rapporter** — informer teamet
