# CI/CD & Deployment

## Kontekst

Workflow: Utveckla lokalt med Docker → push till GitHub → Redeploy i Coolify → live pa `app.item.intern`.

**OBS:** GitHub webhooks fungerar inte eftersom servern ar intern. Deploy triggas manuellt via Coolify UI (Redeploy-knappen).

## Deploy-modeller i Coolify

### 1. Docker Compose (rekommenderat)

```
Utvecklare → git push → Coolify UI → Redeploy → build → deploy
```

Steg:
1. New Resource → Public Repository (eller Private med Deploy Key)
2. Klistra in GitHub-URL
3. Build Pack: **Docker Compose**
4. Compose Location: `/docker-compose.yaml` (OBS: `.yaml` inte `.yml`)
5. Satt Domains: `http://appnamn.item.intern`
6. Deploy

### 2. Privata repos

Anvand Deploy Key:
1. Skapa SSH-nyckel i Coolify (Security → Private Keys → + Add)
2. Kopiera public key till GitHub-repot (Settings → Deploy keys)
3. Krav: admin-access pa repot. Utan det — forka till eget konto.

## docker-compose.yaml for Coolify

```yaml
services:
  app:
    build: .
    environment:
      - SERVICE_FQDN_APP_3000    # Coolify routar till port 3000
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: myapp
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db-data:
```

- Ingen `ports:` — Traefik hanterar extern routing
- Databaser ska INTE ha SERVICE_FQDN
- Satt SERVICE_FQDN-varde explicit i Coolify Environment Variables for att undvika auto-genererad sslip.io-doman

## Dockerfile — Node.js + Prisma + bcrypt

**VIKTIGT: Anvand `node:20-slim` (Debian), INTE Alpine.** Alpine ger OpenSSL- och musl-konflikter med Prisma och bcrypt.

```dockerfile
FROM node:20-slim AS base

FROM base AS deps
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
COPY prisma ./prisma/
RUN npm ci --ignore-scripts && npm rebuild bcrypt

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build

FROM base AS runner
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production
ENV PRISMA_QUERY_ENGINE_LIBRARY=/app/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node

RUN groupadd --system --gid 1001 nodejs && useradd --system --uid 1001 nextjs

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

### Viktiga detaljer

- `npm ci --ignore-scripts` — postinstall (prisma generate) kraschar utan DATABASE_URL
- `npm rebuild bcrypt` — kompilerar native modul for ratt plattform
- Kopiera bcrypt explicit — Next.js standalone inkluderar det inte
- Installera openssl i runner — Prisma behover det
- Satt PRISMA_QUERY_ENGINE_LIBRARY — Prisma auto-detect valjer ibland fel version
- **Verifiera bygget pa servern** med `docker build --no-cache` innan push till Coolify

### Prisma schema

```prisma
generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native", "debian-openssl-3.0.x"]
}
```

## Miljövariabler

- **Lokalt:** `.env`-fil (i .gitignore)
- **Coolify:** Environment Variables i UI (krypterade)
- Aldrig hardkoda credentials i kod eller Dockerfile
- Migrations/seed kors manuellt via `docker exec` eller temp-container

## Vanliga problem

### 404 page not found
Traefik vet inte vilken port containern lyssnar pa. Losning: SERVICE_FQDN med port-suffix, eller explicit Traefik-label.

### Container restartlopar
Kolla loggar: `ssh eric@192.168.50.150 "sudo docker logs <container> --tail 30"`

### npm ci failar i Docker
Kontrollera att package-lock.json ar synkad med package.json. Kor `npm install --ignore-scripts` lokalt och pusha lock-filen.

### Prisma/bcrypt runtime-krasch
Anvand Debian-slim, inte Alpine. Se Dockerfile-mall ovan.

## Sjekkliste for ny app

- [ ] Dockerfile fungerar pa servern (`docker build --no-cache`)
- [ ] `docker-compose.yaml` (inte .yml) med SERVICE_FQDN
- [ ] `.dockerignore` finns (node_modules, .git, .env, .next)
- [ ] Healthcheck i compose eller Dockerfile
- [ ] GitHub-repo (public eller private med deploy key)
- [ ] Coolify-projekt konfigurerat med ratt branch
- [ ] Domains satt till `http://app.item.intern`
- [ ] Miljövariabler satta i Coolify UI
- [ ] Forsta deploy OK
- [ ] Migrations/seed korda om DB anvands
