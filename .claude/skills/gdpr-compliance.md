# GDPR Compliance — Intern Server + Kundedata

## Kontekst

Serveren kan håndtere kundedata (logger fra Enonic-kunder via OpenSearch).
Item Consulting er norsk selskap — GDPR gjelder fullt ut.

## Prinsipper

### Dataminimering
- Samle kun logger som er nødvendige for overvåking
- Ikke lagre persondata i logger med mindre nødvendig
- Sett retensjon (slettefrister) på alle indekser

### OpenSearch-retensjon
```bash
# ISM (Index State Management) policy for automatisk sletting
# Logger-kunder: 7 dager
# Logger + AI-kunder: 14 dager
# Ekspert-kunder: 30 dager
# Dedikert-kunder: 90 dager
```

### Index Lifecycle
```json
{
  "policy": {
    "description": "Slett logger etter retensjon",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": { "min_index_age": "7d" }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [{ "delete": {} }]
      }
    ]
  }
}
```

## Persondata i logger

### Hva kan dukke opp
- IP-adresser (persondata under GDPR)
- Brukernavn / e-post i audit-logger
- Session-IDer som kan kobles til personer
- Søkeord fra besøkende

### Tiltak
- **Anonymiser IP-adresser** i Fluent Bit før de sendes til OpenSearch
- **Pseudonymiser brukernavn** der mulig
- **Dokumenter** hvilke persondata som samles inn per kunde

### Fluent Bit IP-anonymisering
```ini
[FILTER]
    Name    modify
    Match   *
    # Erstatt siste oktett med 0
    Rename  client_ip  original_ip
    # Bruk lua-filter for full anonymisering
```

## Databehandleravtale (DPA)

For Enonic Application Monitor-kunder:
- Item er **databehandler**, kunden er **behandlingsansvarlig**
- Krever skriftlig databehandleravtale
- Beskriv: formål, datakategorier, sikkerhetstiltak, retensjon, sletting

### Minimumskrav i avtalen
1. Formål med behandlingen (applikasjonsovervåking)
2. Kategorier av persondata (IP, brukernavn, audit-data)
3. Retensjon (avhengig av tjenestenivå)
4. Sikkerhetstiltak (kryptering, tilgangskontroll, backup)
5. Rett til sletting (kunden kan kreve sletting når som helst)
6. Underbehandlere (ingen — alt kjøres på egen infra i Norge)

## Datalokalitet

- **Intern server:** Data lagret fysisk på Items kontor i Norge
- **VPS (produksjon):** Bruk norsk leverandør (UpCloud Stavanger, Host1.no Oslo)
- **Ingen data til utlandet** med mindre kunden eksplisitt samtykker
- **AI-analyse:** Loggdata sendes til Claude/OpenAI API — krever samtykke eller anonymisering først

### AI og GDPR
- Anonymiser/pseudonymiser logger FØR de sendes til LLM
- Alternativ: tilby "disable external AI" — kun lokal analyse
- Dokumenter dataflyt i personvernserklæringen

## Sletting

### Kundens rett til sletting
```bash
# Slett alle indekser for en kunde
curl -X DELETE "https://opensearch:9200/enonic-kundenavn-*" \
  -u admin:password --insecure

# Bekreft sletting
curl -X GET "https://opensearch:9200/_cat/indices/enonic-kundenavn-*" \
  -u admin:password --insecure
```

### Ved opphør av kundeforhold
1. Eksporter data til kunden (om ønsket)
2. Slett alle indekser
3. Slett dashboards og konfigurasjoner
4. Dokumenter slettingen
5. Bekreft skriftlig til kunden

## Sjekkliste

### Per kunde
- [ ] Databehandleravtale signert
- [ ] Persondata-kategorier dokumentert
- [ ] Retensjon konfigurert i OpenSearch ISM
- [ ] AI-bruk avklart (med/uten)
- [ ] Kontaktperson for personvern hos kunden

### Generelt
- [ ] Personvernerklæring oppdatert
- [ ] Behandlingsprotokoll ført (Art. 30)
- [ ] Sikkerhetstiltak dokumentert
- [ ] Rutine for databrudd (72 timers varsel til Datatilsynet)
