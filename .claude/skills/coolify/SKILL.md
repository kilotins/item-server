---
name: coolify
description: Expertise about Coolify PaaS deployment, Docker Compose configuration, Traefik proxy routing, domains, Teams, and troubleshooting on item.intern server.
when_to_use: Coolify deployment, Docker Compose for Coolify, Traefik routing, SERVICE_FQDN variables, domain setup, Coolify troubleshooting
argument-hint: [question or task about Coolify]
---

# Coolify Expertise

## Server

- **Host:** Lenovo P15s, Debian 12, 32 GB RAM
- **IP:** 192.168.50.150
- **DNS:** dnsmasq med wildcard `*.item.intern` -> 192.168.50.150
- **Coolify UI:** https://coolify.item.intern (port 8000 bound to localhost, Traefik routes via HTTPS)
- **Coolify version:** v4.0.0-beta.473
- **Proxy:** Traefik v3.6
- **Docker:** v29.4.0, Compose v5.1.2

## Coolify kors som Docker-containrar

Coolify installeras via `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash` och kor som Docker-containrar (inte systemd). Containrar:
- coolify (huvudapp)
- coolify-proxy (Traefik)
- coolify-db (PostgreSQL 15)
- coolify-redis (Redis 7)
- coolify-realtime
- coolify-sentinel

Alla ska ha `restart: always` for autostart vid reboot.

## Deploya en app via Docker Compose

### Steg-for-steg i GUI

1. **Projects** -> **Add New Project**
2. Klicka pa environment -> **Add New Resource**
3. **Public Repository** -> klistra in GitHub-URL
4. Build Pack: **Docker Compose**
5. Compose Location: `/docker-compose.yaml` (OBS: `.yaml` inte `.yml` — Coolify default)
6. Continue
7. Satt **Domains** for tjansten (t.ex. `http://myapp.item.intern`)
8. Deploy

### docker-compose.yaml for Coolify

Nyckelregel: Anvand `SERVICE_FQDN_<NAMN>_<PORT>` environment-variabel for att tala om for Coolify vilken port Traefik ska routa till.

```yaml
services:
  myapp:
    build: .
    environment:
      - SERVICE_FQDN_MYAPP_3000    # Coolify routar trafik till port 3000
    env_file:
      - .env
    restart: unless-stopped
```

- **Ingen `ports:`-mappning behovs** — Traefik hanterar extern atkomst
- **Ingen Traefik-labels behovs** — SERVICE_FQDN skoter det
- **Databaser** ska INTE ha SERVICE_FQDN — de ska bara vara interna
- **OBS:** Coolify auto-genererar en extra doman (sslip.io) for SERVICE_FQDN-variabler. For att undvika det, satt variabelns varde explicit i Coolify UI under Environment Variables: `SERVICE_FQDN_MYAPP_3000=http://myapp.item.intern`

### Multi-container setup

```yaml
services:
  frontend:
    build: ./frontend
    environment:
      - SERVICE_FQDN_FRONTEND_3000

  backend:
    build: ./backend
    environment:
      - SERVICE_FQDN_BACKEND_8080

  database:
    image: postgres:16
    volumes:
      - db-data:/var/lib/postgresql/data
    # Ingen SERVICE_FQDN — intern tjänst

volumes:
  db-data:
```

Tjanster i samma compose kan prata med varandra via servicenamn (t.ex. `http://backend:8080`).

### Domains i Coolify UI

Under Configuration -> Domains for [tjanst], ange:
- `http://myapp.item.intern` for HTTP
- Coolify stodjer flera domaner separerade med komma

## Traefik-routing

### Hur det fungerar

```
Webblasare -> myapp.item.intern:80
  -> Traefik (kollar hostname)
    -> Container:APP_PORT
```

Traefik routar baserat pa domannamn. Flera appar kan kora pa samma port internt utan konflikt — varje container har isolerat natverk.

### Vanligt problem: 404 page not found

Orsak: Traefik vet inte vilken port containern lyssnar pa (default port 80).

Losning: Lagg till `SERVICE_FQDN_<NAMN>_<PORT>` i docker-compose.yaml.

**OBS:** SERVICE_FQDN port-suffix ar buggig i Coolify beta.473 — den kan ignorera porten. Om 404 kvarstar efter deploy, lagg till explicit label:
```yaml
labels:
  - "traefik.http.services.<service-name>.loadbalancer.server.port=<PORT>"
```

Tips: Gor en clean redeploy (ta bort resursen helt och skapa om) — ibland fixar det SERVICE_FQDN-parsningen.

### Natverk

Coolify skapar ett Docker-natverk per deployment. Traefik (coolify-proxy) ansluter till nätverket automatiskt. Kontrollera med:
```bash
sudo docker inspect <container> --format '{{json .NetworkSettings.Networks}}'
```

## DNS

dnsmasq-konfiguration (`/etc/dnsmasq.d/*.conf`):
```
address=/item.intern/192.168.50.150
```

Wildcard — alla `*.item.intern` pekar pa servern. Inga extra DNS-poster behovs for nya appar.

## Felsökning

### Kolla containrar
```bash
ssh eric@192.168.50.150 "sudo docker ps"
```

### Kolla Traefik-labels pa en container
```bash
sudo docker inspect <container> --format '{{json .Config.Labels}}' | python3 -m json.tool | grep traefik
```

### Kolla natverk
```bash
sudo docker network ls
sudo docker inspect <container> --format '{{json .NetworkSettings.Networks}}'
```

### Coolify-loggar
Tillgangliga i GUI under Deployments -> Logs

### Compose-fil hittas inte
Coolify soker efter `/docker-compose.yaml` (med `.yaml`). Om filen heter `.yml`, andra Docker Compose Location i Configuration.

## Webhooks och auto-deploy

GitHub webhooks fungerar inte direkt eftersom item.intern inte ar natbart fran internet. Alternativ:
1. **Cloudflare Tunnel** — exponera webhook-endpoint
2. **Polling** — om Coolify stodjer det
3. **Manuell trigger** via Coolify API efter push

## Filnamnskonvention

Anvand `docker-compose.yaml` (inte `.yml`) for att matcha Coolify's default.

## Dockerfile best practices for Coolify

### Undvik Alpine for Node.js + Prisma + bcrypt

Anvand `node:20-slim` (Debian) for ALLA stages. Alpine saknar OpenSSL 1.1 och ger musl/glibc-konflikter.

```dockerfile
FROM node:20-slim AS base

# --- Dependencies ---
FROM base AS deps
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
COPY prisma ./prisma/
RUN npm ci --ignore-scripts && npm rebuild bcrypt

# --- Build ---
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build

# --- Production ---
FROM base AS runner
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production
ENV PRISMA_QUERY_ENGINE_LIBRARY=/app/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node

RUN groupadd --system --gid 1001 nodejs
RUN useradd --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=builder /app/node_modules/bcrypt ./node_modules/bcrypt

USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```

### Prisma schema for Debian

```prisma
generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "debian-openssl-3.0.x"]
}
```

### Viktiga detaljer

- `npm ci --ignore-scripts` — undviker att postinstall (prisma generate) kor utan DATABASE_URL
- `npm rebuild bcrypt` — kompilerar native modul separat
- Kopiera bcrypt explicit till runner — Next.js standalone inkluderar det inte
- Installera `openssl` i runner — Prisma behover det
- Satt `PRISMA_QUERY_ENGINE_LIBRARY` — Prisma auto-detect valjer ibland fel OpenSSL-version
- Verifiera bygget pa servern med `docker build --no-cache` innan push till Coolify

## Privata repos

For privata GitHub-repos, anvand **Deploy Key** i Coolify:
1. Skapa en SSH-nyckel i Coolify (Security -> Private Keys -> + Add -> Generate ED25519)
2. Kopiera public key
3. Lagg till som Deploy Key i GitHub-repot (Settings -> Deploy keys)
4. Valj nyckeln nar du skapar resursen i Coolify

OBS: Du behover admin-access pa GitHub-repot for att lagga till deploy keys. Om du inte har det, forka repot till ditt eget konto.

## SSL / HTTPS

Wildcard SSL-cert for `*.item.intern` (giltig till 2028-07-15), genererat med mkcert.

- Cert: `/data/coolify/proxy/certs/item.intern.pem`
- Key: `/data/coolify/proxy/certs/item.intern-key.pem`
- CA root: `/opt/ssl/ca/`
- Traefik TLS-config: `/data/coolify/proxy/dynamic/certificates.yml`

Alla nya appar far HTTPS automatiskt via wildcard-certet. Satt doman till `https://myapp.item.intern` (inte http).

## Coolify API

API-token sparad i `.env` (gitignored). Permissions: read, write, deploy.

### Bas-URL
```
https://coolify.item.intern/api/v1
```

### Auth
```bash
curl -k -H "Authorization: Bearer $(grep COOLIFY_API_TOKEN .env | cut -d= -f2)" \
  https://coolify.item.intern/api/v1/applications
```

### Vanliga operationer

**Lista appar:**
```bash
GET /api/v1/applications
```

**Uppdatera doman (dockerimage-app):**
```bash
PATCH /api/v1/applications/{uuid}
{"domains": "https://myapp.item.intern"}
```

**Uppdatera doman (docker-compose-app):**
```bash
PATCH /api/v1/applications/{uuid}
{"docker_compose_domains": {"app": {"domain": "https://myapp.item.intern", "name": "app"}}}
```
OBS: `fqdn`-faltet accepteras INTE via PATCH. Anvand `domains` istallet.

**Uppdatera env-variabel:**
```bash
PATCH /api/v1/applications/{uuid}/envs
{"key": "MY_VAR", "value": "new_value", "is_preview": false}
```

**Restart/redeploy:**
```bash
POST /api/v1/applications/{uuid}/restart
```

**Kolla deploy-status:**
```bash
GET /api/v1/deployments/{deployment_uuid}
```

## Aktiva deployments (2026-04-15)

| App | URL | Repo | Branch |
|-----|-----|------|--------|
| LogPilot | https://logpilot.item.intern | kilotins/ws-log-analyzer | main |
| Item CRM | https://crm.item.intern | kilotins/item-crm (fork) | main |
