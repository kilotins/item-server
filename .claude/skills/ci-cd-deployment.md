# CI/CD & Deployment

## Kontekst

Workflow: Utvikle lokalt med Docker → push til GitHub → Coolify deployar automatisk → live på `app.dev.item.no`.

## Deploy-modeller i Coolify

### 1. Git Push Deploy (anbefalt)
```
Utvikler → git push → GitHub → Coolify webhook → build → deploy
```
- Coolify kobles til GitHub-repo
- Webhook trigger ved push til main/master
- Bygg basert på Dockerfile, Nixpacks, eller Docker Compose
- Automatisk SSL via Let's Encrypt eller Cloudflare

### Oppsett i Coolify
1. Connect GitHub account (OAuth)
2. New Resource → Public/Private Repository
3. Velg repo + branch
4. Build pack: Dockerfile / Nixpacks / Docker Compose
5. Set domene: `appnavn.dev.item.no`
6. Deploy

### 2. Preview Deployments
- Coolify kan deploye PR-branches automatisk
- Hver PR får sin egen URL: `pr-123.dev.item.no`
- Slettes automatisk når PR lukkes

### 3. Manuelt (Docker Compose)
For stacks som OpenSearch — deploy via Coolify UI med compose-fil.

## Lokal utvikling → produksjon

### Anbefalt workflow
```
1. Utvikle lokalt med Docker/Docker Compose
2. Test lokalt: docker compose up
3. Push til GitHub
4. Coolify bygger og deployar automatisk
5. Sjekk: https://appnavn.dev.item.no
```

### Dockerfile best practices
```dockerfile
# Multi-stage build for mindre images
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Docker Compose for lokal utvikling
```yaml
# docker-compose.yml (lokalt)
services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app        # Hot reload lokalt
      - /app/node_modules
    environment:
      - NODE_ENV=development

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: localdev
    ports:
      - "5432:5432"
```

### Miljøvariabler
- **Lokalt:** `.env`-fil (i .gitignore)
- **Coolify:** Environment Variables i UI (krypterte)
- Aldri hardkode credentials i kode eller Dockerfile

## GitHub Actions (valgfritt)

### Enkel CI — test før deploy
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm test
      - run: npm run lint
```

Coolify deployar etter CI passerer (konfigurerbart).

### For Python-prosjekter
```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -e ".[test]"
      - run: pytest
```

## Domene-oppsett

### DNS-konfigurasjon for item.no
```
# Hos DNS-leverandør for item.no:
# Wildcard CNAME som peker til Cloudflare Tunnel
*.dev.item.no  CNAME  <tunnel-id>.cfargotunnel.com
```

### Per app i Coolify
- Sett domene i app-innstillinger
- Coolify konfigurerer Traefik automatisk
- SSL via Let's Encrypt (internt) eller Cloudflare (eksternt)

## Rollback

### I Coolify
- Coolify holder historikk over deployments
- Klikk "Rollback" på forrige deployment
- Eller: push en revert-commit til git

### Manuelt
```bash
# Se tilgjengelige images
docker images | grep appnavn

# Kjør forrige versjon
docker stop appnavn
docker run -d --name appnavn appnavn:previous-tag
```

## Monitoring av deployments

### Coolify UI
- Real-time build logs
- Container status (running/stopped/error)
- CPU/RAM/nettverk per container

### Healthchecks
```yaml
# I docker-compose.yml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Sjekkliste for ny app

- [ ] Dockerfile fungerer lokalt (`docker build && docker run`)
- [ ] `.dockerignore` finnes (ekskluder node_modules, .git, .env)
- [ ] Miljøvariabler dokumentert i `.env.example`
- [ ] Healthcheck-endepunkt implementert
- [ ] GitHub-repo opprettet
- [ ] Coolify-prosjekt konfigurert
- [ ] Domene satt opp
- [ ] Første deploy OK
