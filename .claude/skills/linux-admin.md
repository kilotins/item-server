# Linux Administration — Debian Server

## Felsökning

### Systemet svarar långsamt
```bash
# Överblick — CPU, minne, processer
htop

# Realtidsövervakning med nmon
nmon

# Vad äter disk I/O?
sudo iotop

# Historisk CPU/minne/disk (sysstat/sar)
sar -u 5 3          # CPU senaste 3 mätningar, 5s intervall
sar -r 5 3          # Minne
sar -d 5 3          # Disk I/O

# Load average
uptime

# Vad tar mest minne?
ps aux --sort=-%mem | head -20
```

### Diskproblem
```bash
# Diskutrymme per partition
df -h

# Interaktiv — hitta vad som äter plats
ncdu /

# Docker-specifikt — images, volumes, build cache
docker system df
docker system prune -a    # VARNING: tar bort oanvända images/volumes
```

### Nätverksproblem
```bash
# Öppna portar och vilken process som lyssnar
sudo ss -tlnp

# DNS-uppslag
dig myapp.item.intern
nslookup myapp.item.intern

# Testa anslutning
curl -v https://myapp.item.intern
ping 192.168.50.150

# Brandväggsregler
sudo ufw status verbose
```

### Loggfiler
```bash
# Systemloggar (journald)
journalctl -f                     # Följ i realtid
journalctl -u sshd --since today  # SSH idag
journalctl -p err --since "1 hour ago"  # Fel senaste timmen

# Fail2ban
sudo fail2ban-client status sshd

# Misslyckade inloggningar
journalctl -u sshd | grep "Failed"

# Vem har loggat in
last
who
```

## Docker-felsökning

### Containrar
```bash
# Status på alla containrar
docker ps -a

# Resursanvändning i realtid
docker stats

# Loggar från en container
docker logs <container> --tail 100 -f

# Kör kommando i en körande container
docker exec -it <container> /bin/sh

# Inspektera container (nätverk, volymer, env)
docker inspect <container>

# Starta om en container
docker restart <container>
```

### Docker Compose
```bash
# Status
docker compose ps

# Loggar från hela stacken
docker compose logs -f

# Starta om en tjänst
docker compose restart <service>

# Ta ner och upp igen
docker compose down && docker compose up -d

# Validera compose-fil
docker compose config
```

### Nätverk
```bash
# Lista Docker-nätverk
docker network ls

# Inspektera nätverk (se vilka containrar som är anslutna)
docker network inspect <network>

# Testa anslutning mellan containrar
docker exec -it <container> ping <other-container>
```

### Volymer och data
```bash
# Lista volymer
docker volume ls

# Inspektera volym (hitta mount path)
docker volume inspect <volume>

# Backup av volym
docker run --rm -v <volume>:/data -v $(pwd):/backup \
  alpine tar czf /backup/volume-backup.tar.gz /data
```

## Systemadministration

### Tjänster (systemd)
```bash
# Status
sudo systemctl status <service>

# Starta/stoppa/starta om
sudo systemctl start|stop|restart <service>

# Aktivera/inaktivera vid boot
sudo systemctl enable|disable <service>

# Lista alla aktiva tjänster
systemctl list-units --type=service --state=running
```

### Användare och grupper
```bash
# Lägg till användare i item-gruppen
sudo usermod -aG item <username>

# Se gruppmedlemskap
groups <username>
id <username>

# Lista alla i en grupp
getent group item
```

### SSH
```bash
# Anslut (efter härdning)
ssh -p 10022 eric@192.168.50.150

# Kopiera SSH-nyckel till servern
ssh-copy-id -p 10022 -i ~/.ssh/id_ed25519.pub eric@192.168.50.150

# Kopiera fil till/från server
scp -P 10022 fil.txt eric@192.168.50.150:/tmp/
scp -P 10022 eric@192.168.50.150:/var/log/syslog ./
```

### tmux — behåll sessioner
```bash
# Ny session
tmux new -s setup

# Koppla ifrån (sessionen lever kvar)
# Ctrl+B, sedan D

# Lista sessioner
tmux ls

# Återanslut
tmux attach -t setup
```

## Coolify-administration

### Via CLI
```bash
# Coolify-status
sudo systemctl status coolify

# Coolify-loggar
docker logs coolify -f

# Traefik-loggar (reverse proxy)
docker logs coolify-proxy -f

# Se alla Coolify-containrar
docker ps --filter "label=coolify.managed=true"
```

### Vanliga problem
```bash
# Coolify UI nås inte
sudo ufw status          # Port 8000 öppen?
docker ps | grep coolify # Kör containern?

# Deploy fastnar
docker logs coolify -f   # Kolla Coolify-loggar
df -h                    # Disk full?

# SSL fungerar inte
docker logs coolify-proxy -f   # Traefik-loggar
ls -la /opt/ssl/certs/         # Cert-filer finns?
```

## Prestandaövervakning

### Snabbkoll
```bash
# Allt-i-ett
nmon

# CPU + minne + processer
htop

# Disk I/O
sudo iotop
```

### Historisk data (sar)
```bash
# CPU-historik idag
sar -u

# Minne idag
sar -r

# Disk I/O idag
sar -d

# Nätverkstrafik idag
sar -n DEV

# Specifik dag
sar -u -f /var/log/sysstat/sa14   # dag 14
```
