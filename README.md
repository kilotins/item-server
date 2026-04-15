# item-server

Intern utviklingsserver for Item Consulting — Debian 12 + Coolify pa Lenovo P15s (32 GB RAM).

## Hva er dette?

Oppsettscripts og konfigurasjon for Items interne container-plattform. Ansatte kan deploye egne prosjekter via git push, og vi kan kjore demoer for kunder.

## Tre soner

- **logpilot** — LogPilot demo/test
- **enonic** — OpenSearch-stack (Enonic Application Monitor PoC)
- **sandbox** — Ansattes egne prosjekter

## Kom i gang

### 1. Installer Debian 12

Se `docs/debian-install.md` for steg-for-steg.

### 2. Kjor base setup

```bash
ssh eric@<server-ip>
git clone <dette-repoet>
cd item-server
chmod +x scripts/*.sh
sudo ./scripts/01-base-setup.sh
sudo ./scripts/02-install-coolify.sh
sudo ./scripts/03-dns-setup.sh
```

### 3. Deploy OpenSearch

```bash
# Kjores via Coolify UI som Docker Compose-prosjekt
# Eller manuelt:
cd compose/opensearch
docker compose up -d
```

## Struktur

```
item-server/
├── README.md
├── CLAUDE.md              — kontekst for Claude Code
├── scripts/
│   ├── 01-base-setup.sh   — pakker, brannmur, SSH-herding
│   ├── 02-install-coolify.sh
│   ├── 03-dns-setup.sh    — dnsmasq for *.item.lan
│   └── 04-opensearch.sh   — OpenSearch kernel-settings
├── configs/
│   ├── sshd_config        — herdet SSH-konfigurasjon
│   └── dnsmasq.conf       — intern DNS
├── compose/
│   └── opensearch/
│       └── docker-compose.yml
└── docs/
    ├── debian-install.md  — installasjonsveiledning
    └── forslag-intern-server.md
```

## Lisens

Internt prosjekt — Item Consulting AS
