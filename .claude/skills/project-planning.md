# Project Planning — Item Server

## Kontekst

Planlegging og oppfølging av serveroppsett, PoC-prosjekter, og tjenesteutvikling.

## Prosjektstruktur

### Tre parallelle spor

| Spor | Mål | Tidslinje |
|------|-----|-----------|
| **Infrastruktur** | Debian + Coolify + nettverk | Uke 1-2 |
| **Enonic Monitor PoC** | OpenSearch-stack + demo-dashboard | Uke 2-4 |
| **Team onboarding** | Alle kan deploye | Uke 3-4 |

## Fase 1: Infrastruktur (uke 1-2)

### Dag 1: OS + base
- [ ] Installer Debian 12 på Lenovo P15s
- [ ] Kjør `01-base-setup.sh` (pakker, brannmur, SSH)
- [ ] Fast IP + SSH-nøkler
- [ ] Test SSH fra Mac

### Dag 2: Coolify + nettverk
- [ ] Kjør `02-install-coolify.sh`
- [ ] Opprett admin-konto i Coolify UI
- [ ] Opprett Teams: logpilot, enonic, sandbox
- [ ] Kjør `03-dns-setup.sh` (intern DNS)
- [ ] Test: `ping test.item.intern`

### Dag 3: Ekstern tilgang
- [ ] Sett opp Cloudflare Tunnel
- [ ] DNS: `*.dev.item.no` → Cloudflare Tunnel
- [ ] Cloudflare Access: @item.no policy
- [ ] Test: `https://test.dev.item.no`

### Dag 4: Sikkerhet + backup
- [ ] Installer fail2ban
- [ ] Herd SSH (disable password)
- [ ] Docker log rotation
- [ ] Backup-script + cron

## Fase 2: Enonic Monitor PoC (uke 2-4)

### Uke 2: OpenSearch-stack
- [ ] Kjør `04-opensearch.sh` (kernel settings)
- [ ] Deploy OpenSearch compose-stack via Coolify
- [ ] Verifiser OpenSearch API: `curl https://localhost:9200`
- [ ] Åpne OpenSearch Dashboards: `opensearch.dev.item.no`

### Uke 3: Demo-dashboard
- [ ] Opprett demo-indeks med syntetiske Enonic-logger
- [ ] Bygg dashboard: oppetid, responstid, feil, SSL
- [ ] Konfigurer alerting (e-post/Slack)
- [ ] Sett opp anomalydeteksjon (RCF)

### Uke 4: Kundevisning
- [ ] Polér dashboard for Fiskeridirektorat-demo
- [ ] Cloudflare Access for kundeinlogging
- [ ] Forbered demo-script (5 min)
- [ ] Kontakt 2-3 pilotkunder

## Fase 3: Team onboarding (uke 3-4)

### Forberedelse
- [ ] Skriv enkel "Kom i gang"-guide for teamet
- [ ] Lag mal-prosjekt (Node.js + Dockerfile)
- [ ] Test deploy av malprosjekt

### Onboarding
- [ ] Inviter teammedlemmer til Coolify
- [ ] 30 min demo/workshop
- [ ] Borse tester å deploye et prosjekt
- [ ] Samle feedback, juster

## Beslutningslogg

Bruk denne for å dokumentere viktige beslutninger:

| Dato | Beslutning | Begrunnelse |
|------|-----------|-------------|
| 2026-04-14 | Coolify over Dokploy | Apache 2.0, større community, mer funksjoner |
| 2026-04-14 | Debian over Ubuntu | Brukerens preferanse, mindre bloat |
| 2026-04-14 | Cloudflare Tunnel for ekstern tilgang | Gratis, ingen åpne porter, DDoS-beskyttelse |

## Risikoregister

| Risiko | Sannsynlighet | Tiltak |
|--------|---------------|--------|
| RAM ikke nok for alle workloads | Middels | Sett minnegrenser per container, prioriter soner |
| Strømbrudd mister data | Lav-Middels | UPS + backup |
| Sandbox-container tar ned serveren | Middels | Ressursgrenser, separate Docker-nettverk |
| Ekstern tilgang kompromittert | Lav | Cloudflare Access, ingen åpne porter |
| Disk full (OpenSearch-logger) | Middels | Retensjon via ISM, monitoring |

## Milepæler

| Milepæl | Mål | Frist |
|---------|-----|-------|
| M1 | SSH fungerer til Debian-server | Uke 1 |
| M2 | Coolify UI tilgjengelig | Uke 1 |
| M3 | Første app deployat via Coolify | Uke 1 |
| M4 | OpenSearch-stack kjører | Uke 2 |
| M5 | Ekstern tilgang fungerer (*.dev.item.no) | Uke 2 |
| M6 | Demo-dashboard klart | Uke 3 |
| M7 | Teamet kan deploye selv | Uke 4 |
| M8 | Første kundekontakt | Uke 5-6 |
