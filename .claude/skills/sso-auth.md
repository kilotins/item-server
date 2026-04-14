# SSO & Authentication

## Kontekst

Autentisering for tre lag:
1. **Coolify** — hvem kan deploye apper
2. **Eksponerte apper** — hvem kan nå kundedemoer eksternt
3. **OpenSearch Dashboards** — hvem kan se kundelogger

## Coolify Auth

### Innebygd brukerhandtering
- Coolify har eget bruker/passord-system
- Opprett én admin (Eric) + brukere per teammedlem
- Teams begrenser tilgang til prosjekter

### Oppsett
1. Første bruker som registrerer seg blir admin
2. Admin inviterer teammedlemmer via e-post
3. Tildel bruker til riktig Team (logpilot/enonic/sandbox)

## Cloudflare Access (Zero Trust)

### Hva det gir
- SSO foran alle eksponerte tjenester
- Støtter: GitHub, Google, OIDC, One-Time Pin (e-post)
- Gratis for opptil 50 brukere
- Ingen kode-endringer i appene

### Oppsett
```
Cloudflare Dashboard → Zero Trust → Access → Applications

1. Add Application → Self-hosted
2. Application domain: opensearch.dev.item.no
3. Policy: Allow
   - Emails ending in: @item.no
   - Eller: specific emails
4. Session duration: 24 hours
```

### Eksempel-policies

| Tjeneste | Domene | Policy |
|----------|--------|--------|
| OpenSearch Dashboards | opensearch.dev.item.no | Kun @item.no |
| LogPilot demo | logpilot.dev.item.no | Åpen (demo) eller @item.no |
| Kundedashboard | kunde.dev.item.no | Spesifikke e-poster |
| Coolify UI | Ikke eksponert eksternt | Kun internt nett |

### Per-kunde tilgang (Enonic Monitor)
```
Policy: "Fiskeridirektoratet"
  Allow: e-post i lista (it@fiskeridir.no, drift@fiskeridir.no)
  Session: 24 timer
  Require: Norwegian IP range (valgfritt ekstra lag)
```

## OpenSearch Security

### Innebygd rollebasert tilgangskontroll
OpenSearch har Security-plugin med:
- Interne brukere og roller
- Backend-roller koblet til SSO
- Index-level permissions

### Multitenancy
```yaml
# Opprett en bruker per kunde med tilgang kun til egne indekser
# opensearch-security/internal_users.yml

fiskeridirektoratet:
  hash: "<bcrypt hash>"
  backend_roles:
    - "kunde_fiskeridir"

# opensearch-security/roles.yml
kunde_fiskeridir:
  index_permissions:
    - index_patterns:
        - "enonic-fiskeridir-*"
      allowed_actions:
        - "read"
        - "search"
```

### Dashboard-spaces
- Opprett et dashboard-space per kunde
- Kunden ser kun sine egne data
- Admins (Item) ser alt

## Tailscale (intern VPN)

### Alternativ til Cloudflare for intern tilgang
```bash
# Installer på serveren
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Installer på hver utviklermaskin
# Alle får tilgang via Tailscale IP (100.x.x.x)
```

### Fordeler
- Zero config VPN
- Fungerer bak NAT uten port forwarding
- MagicDNS: `item-server.tail12345.ts.net`
- Gratis for opptil 100 enheter

### Kombinert oppsett
- **Tailscale** for intern tilgang (teamet)
- **Cloudflare Tunnel + Access** for ekstern tilgang (kunder)

## Sjekkliste

- [ ] Coolify admin-bruker opprettet
- [ ] Teammedlemmer invitert til Coolify
- [ ] Cloudflare Access konfigurert for eksterne tjenester
- [ ] OpenSearch-brukere opprettet per kunde
- [ ] Coolify UI IKKE eksponert eksternt
- [ ] SSH kun nøkkelbasert
- [ ] Tailscale installert for intern remote-tilgang
