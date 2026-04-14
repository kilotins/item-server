# Item Server — Intern utviklingsserver

## Prosjektoversikt

Sette opp en intern utviklingsserver for Item Consulting pa en Lenovo P15s (32 GB RAM, i7, Nvidia T500) med Debian 12 + Coolify.

## Mal

En plattform der ansatte kan deploye egne prosjekter via git push, og der vi kan kjore demoer (LogPilot, OpenSearch/Enonic Application Monitor) for kunder.

## Maskinvare

- **Maskin:** Lenovo P15s
- **RAM:** 32 GB
- **CPU:** Intel i7
- **GPU:** Nvidia T500 (4 GB VRAM — ikke brukbar for lokale LLM-er)
- **OS:** Debian 12 Server (minimal, ingen desktop)

## Arkitektur

```
Lenovo P15s (32 GB RAM)
└── Debian 12 Server
    └── Coolify (Apache 2.0, open source PaaS)
        ├── [Team: logpilot] — LogPilot demo/test
        ├── [Team: enonic]  — OpenSearch-stack (PoC for kunder)
        └── [Team: sandbox] — Ansattes prosjekter
```

## Coolify

- Open source (Apache 2.0), self-hosted PaaS
- Web UI — git push til deploy, automatisk SSL, domener
- Teams-funksjonalitet for sone-separasjon
- Docker + Docker Compose-stod
- One-click databaser (PostgreSQL, Redis, MySQL)
- Installasjon: `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash`

## Tre soner

| Sone | Formal | Tilgang |
|------|--------|---------|
| **logpilot** | LogPilot demo/test, stabil | Eric + kjerneteam |
| **enonic** | OpenSearch + Dashboards + Fluent Bit | Eric + kjerneteam |
| **sandbox** | Ansattes Claude-prosjekter, eksperimenter | Alle utviklere |

## Nettverk

- Fast intern IP (f.eks. 192.168.1.100)
- Intern DNS via dnsmasq for `*.item.intern`
- Ekstern tilgang: Cloudflare Tunnel (gratis) eller Tailscale
- SSH-tilgang for administrasjon

## OpenSearch-stack (Enonic Application Monitor)

OpenSearch-stacken krever:
- `vm.max_map_count=262144` pa host-niva
- 8-12 GB RAM for OpenSearch
- Persistente volumer med bra I/O
- Docker Compose-deploy via Coolify

### Enonic Application Monitor — forretningscase

Managed overvakingstjeneste for Enonic XP-kunder:
- **Logger:** 1 500 NOK/mnd (automatisert)
- **Logger + AI:** 3 000 NOK/mnd (automatisert)
- **Ekspert:** 6 000 NOK/mnd (2 timer inkl.)
- **Dedikert:** 12 000 NOK/mnd (6 timer inkl.)
- Break-even: 1-2 kunder
- Infrakostnad: ~800 NOK/mnd (VPS i Norge for produksjon)
- Dokumenter: `/Users/eric/Documents/Item 2.0/Forretningscase-*.pdf`

## Implementeringsplan

### Fase 1: Debian-installasjon (fysisk, manuelt)
1. Boot fra Debian 12 netinst USB
2. Minimal install, ingen desktop
3. SSH server aktivert
4. Fast IP eller DHCP-reservasjon
5. BIOS: Power On with AC, Lid Close = do nothing

### Fase 2: Base setup (via SSH, med scripts)
1. Oppdater system, installer grunnpakker
2. Herd SSH (nøkkelbasert, disable password)
3. Sett opp brannmur (ufw)
4. Installer Coolify

### Fase 3: Konfigurering
1. Sett opp Teams i Coolify (logpilot, enonic, sandbox)
2. Konfigurer intern DNS (dnsmasq)
3. Deploy OpenSearch compose-stack
4. Deploy LogPilot demo
5. Sett opp backup (cron + rsync)

### Fase 4: Onboarding
1. Inviter teamet til Coolify
2. Kort demo (30 min)
3. Dokumenter workflow for ansatte

## Viktige kommandoer

```bash
# SSH inn pa serveren
ssh eric@192.168.x.x

# Sjekk status
sudo systemctl status docker
sudo systemctl status coolify

# Se ressursbruk
htop
docker stats

# OpenSearch vm.max_map_count
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

## Skalering

1. **Na:** Debian + Coolify med Teams
2. **Ved behov:** Proxmox hypervisor + 2 VM-er (stabil + sandbox)
3. **Fremtid:** VPS i Norge for produksjon, Lenovo som dev/sandbox

## Relaterte prosjekter

- **LogPilot:** `/Users/eric/ai-workshop/ws-log-analyzer/`
- **Forretningscase:** `/Users/eric/Documents/Item 2.0/`
- **Serverforslag:** `/Users/eric/Documents/Item 2.0/forslag-intern-server.md`
