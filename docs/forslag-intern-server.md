# Forslag: Intern utviklingsserver for Item Consulting

**Dato:** April 2026
**Utarbeidet av:** Eric Askman

---

## Bakgrunn

Vi har en Lenovo P15s (32 GB RAM, i7, Nvidia T500) som vi kan sette opp som intern server for teamet. Malet er en enkel plattform der ansatte kan deploye egne prosjekter, og der vi kan kjore demoer for kunder.

## Hva vi foreslaar

Installere Debian 12 Server med Coolify — en gratis, open source (Apache 2.0) plattform for container-hosting med web UI.

### Tre adskilte soner

| Sone | Formal | Tilgang |
|------|--------|---------|
| **logpilot** | LogPilot demo/test | Eric + kjerneteam |
| **enonic** | OpenSearch-stack, PoC for kunder | Eric + kjerneteam |
| **sandbox** | Ansattes egne prosjekter | Alle utviklere |

Coolify har innebygd "Teams"-funksjonalitet som gir ulik tilgang per sone.

### Hva teamet faar

- **Git push til deploy** — push til GitHub, appen er live med SSL
- **Web UI** — ingen terminalkunskap nodvendig for a deploye
- **Databaser** — PostgreSQL, Redis, MySQL med ett klikk
- **Docker Compose** — for storre stackar (f.eks. OpenSearch)
- **Subdomener** — `prosjekt.item.lan` for hver app
- **5-10 samtidige apper** med 32 GB RAM

### Eksempel pa bruk

- Borse pusher et Claude-prosjekt til GitHub, det er live pa `borses-app.item.lan` etter 2 minutter
- Eric demonstrerer OpenSearch-dashboardet for en Enonic-kunde via Cloudflare Tunnel
- Teamet tester en ny API mot en lokal PostgreSQL-database

## Hvorfor Coolify

Vi evaluerte fire alternativer:

| Plattform | Fordel | Ulempe | Lisens |
|-----------|--------|--------|--------|
| **Coolify** | Mest funksjoner, stort community, one-click apper | Noe mer RAM-bruk | Apache 2.0 |
| Dokploy | Lettest, lavest CPU-bruk | Mixed lisens, faerre apper | Mixed |
| Dokku | Minimalt, CLI-basert | Ingen web UI | MIT |
| Portainer | Bra Docker-oversikt | Ikke PaaS, manuelt oppsett | CE/BE |

**Coolify valgt fordi:** Helt fri lisens, web UI for alle, storst community, og bred funksjonalitet.

## Infrastruktur

### Maskinvare (eksisterende)

| Komponent | Spesifikasjon |
|-----------|--------------|
| Maskin | Lenovo P15s |
| RAM | 32 GB |
| CPU | Intel i7 |
| GPU | Nvidia T500 (4 GB VRAM) |
| Lagring | SSD |

### Kapasitetsplan

| Komponent | RAM-behov |
|-----------|-----------|
| Debian 12 + overhead | ~2 GB |
| Coolify | ~1 GB |
| OpenSearch-stack | ~8-12 GB |
| LogPilot demo | ~0.5 GB |
| Sandbox-apper (5-8 stk) | ~5-10 GB |
| **Ledig buffer** | **~3-8 GB** |

### Nettverk

- Fast intern IP pa kontornettverket (f.eks. 192.168.1.100)
- Intern DNS via dnsmasq for `*.item.lan`
- Ekstern tilgang via **Cloudflare Tunnel** (gratis, ingen aaapne porter) eller **Tailscale** (gratis VPN)

### Sikkerhet og drift

- **Backup:** Cron + rsync til NAS eller ekstern disk
- **UPS:** Anbefales for a unnga datatap ved strombrudd
- **BIOS:** Konfigurer for drift med lokket lukket
- **Oppdateringer:** `unattended-upgrades` for sikkerhetsfikser

## Gjennomforingsplan

| Dag | Aktivitet | Resultat |
|-----|-----------|---------|
| 1 | Installer Debian 12 Server | Fungerende OS |
| 1 | Installer Coolify + konfigurer Teams | Plattform klar |
| 1 | Sett opp intern DNS + fast IP | `*.item.lan` fungerer |
| 2 | Deploy LogPilot som test | Forste app live |
| 2 | Deploy OpenSearch-stack | Demo-miljo klar |
| 2 | Inviter teamet, kort intro | Alle kan deploye |

**Estimert innsats:** 1-2 dager.

## Skalering

Hvis sandboxen vokser og vi trenger sterkere isolering:

1. **Niva 1 (na):** Debian + Coolify med Teams-separasjon
2. **Niva 2 (ved behov):** Proxmox hypervisor + 2 VM-er (stabil + sandbox)
3. **Niva 3 (fremtid):** Flytt produksjon til VPS i Norge, behold Lenovo som dev/sandbox

## Kostnad

| Post | Kostnad |
|------|---------|
| Maskinvare | 0 kr (eksisterende) |
| Coolify | 0 kr (open source) |
| Debian | 0 kr |
| Cloudflare Tunnel | 0 kr |
| UPS (anbefalt) | ~500 kr |
| **Total** | **~500 kr** |

## Neste steg

1. Beslutt om vi kjorer i gang
2. Eric installerer Debian + Coolify (1 dag)
3. Kort demo for teamet (30 min)
4. Alle begynner deploye

---

*Forslaget bygger pa open source-verktoy uten lisenskostnader. Hele oppsettet kan migreres til en storre server eller sky-VM uten endringer i workflow.*
