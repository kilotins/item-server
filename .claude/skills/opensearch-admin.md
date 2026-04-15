# OpenSearch Administration

## Anslutning

```bash
# Lokalt på servern
curl -X GET "https://localhost:9200" -u admin:password --insecure

# Via DNS
curl -X GET "https://opensearch.item.intern:9200" -u admin:password --insecure
```

## Index Management

### Lista index
```bash
# Alla index
curl -X GET "https://localhost:9200/_cat/indices?v" -u admin:password --insecure

# Filtera per kund
curl -X GET "https://localhost:9200/_cat/indices/enonic-*?v" -u admin:password --insecure
```

### Skapa index med mappning
```bash
curl -X PUT "https://localhost:9200/enonic-kundnamn-logs" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "level": { "type": "keyword" },
        "message": { "type": "text" },
        "host": { "type": "keyword" },
        "application": { "type": "keyword" },
        "response_time_ms": { "type": "integer" }
      }
    }
  }'
```

### Ta bort index
```bash
curl -X DELETE "https://localhost:9200/enonic-kundnamn-*" \
  -u admin:password --insecure
```

## ISM — Index State Management (retensjon)

### Skapa ISM-policy
```bash
curl -X PUT "https://localhost:9200/_plugins/_ism/policies/log-retention-7d" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "description": "Delete logs after 7 days",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [],
          "transitions": [
            { "state_name": "delete", "conditions": { "min_index_age": "7d" } }
          ]
        },
        {
          "name": "delete",
          "actions": [{ "delete": {} }]
        }
      ],
      "ism_template": [
        { "index_patterns": ["enonic-*-logs-*"], "priority": 100 }
      ]
    }
  }'
```

### Retensjon per kundnivå
| Nivå | Retensjon | Policy-namn |
|------|-----------|-------------|
| Logger (1 500 NOK) | 7 dagar | `log-retention-7d` |
| Logger + AI (3 000 NOK) | 14 dagar | `log-retention-14d` |
| Ekspert (6 000 NOK) | 30 dagar | `log-retention-30d` |
| Dedikert (12 000 NOK) | 90 dagar | `log-retention-90d` |

### Kontrollera ISM-status
```bash
# Se vilka index som har policies
curl -X GET "https://localhost:9200/_plugins/_ism/explain/*" \
  -u admin:password --insecure
```

## Användare och roller

### Skapa intern användare
```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/internalusers/kundnamn" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "password": "kundenslosenord",
    "backend_roles": ["kund_kundnamn"]
  }'
```

### Skapa roll med index-begränsning
```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/roles/kund_kundnamn" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "index_permissions": [
      {
        "index_patterns": ["enonic-kundnamn-*"],
        "allowed_actions": ["read", "search"]
      }
    ]
  }'
```

### Koppla roll till användare
```bash
curl -X PUT "https://localhost:9200/_plugins/_security/api/rolesmapping/kund_kundnamn" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "backend_roles": ["kund_kundnamn"]
  }'
```

## Fluent Bit — Logginsamling

### Testa att loggar kommer in
```bash
# Se senaste dokument i ett index
curl -X GET "https://localhost:9200/enonic-*/_search?size=5&sort=@timestamp:desc" \
  -u admin:password --insecure

# Räkna dokument
curl -X GET "https://localhost:9200/enonic-*/_count" \
  -u admin:password --insecure
```

### Fluent Bit-status
```bash
# Container-loggar
docker logs fluent-bit --tail 50

# Metrics
curl http://localhost:2020/api/v1/metrics
```

## Prestanda

### Klusterhälsa
```bash
curl -X GET "https://localhost:9200/_cluster/health?pretty" \
  -u admin:password --insecure
```

### Node-statistik
```bash
# Minne, CPU, disk
curl -X GET "https://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,disk.used_percent" \
  -u admin:password --insecure
```

### Långsamma queries
```bash
# Aktivera slow log
curl -X PUT "https://localhost:9200/enonic-*/_settings" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "index.search.slowlog.threshold.query.warn": "5s",
    "index.search.slowlog.threshold.query.info": "2s"
  }'
```

### JVM-minne
```bash
# Kontrollera heap-användning
curl -X GET "https://localhost:9200/_nodes/stats/jvm?pretty" \
  -u admin:password --insecure
```

## AI-integration med itemai (ML Commons)

### Registrera itemai som remote model connector
```bash
# Skapa connector mot itemai (OpenAI-kompatibelt API)
curl -X POST "https://localhost:9200/_plugins/_ml/connectors/_create" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "name": "itemai-llm",
    "description": "Intern LM Studio på itemai",
    "version": "1",
    "protocol": "http",
    "parameters": {
      "model": "openai/gpt-oss-20b"
    },
    "actions": [
      {
        "action_type": "predict",
        "method": "POST",
        "url": "http://itemai:1234/v1/chat/completions",
        "headers": {
          "Content-Type": "application/json"
        },
        "request_body": "{ \"model\": \"${parameters.model}\", \"messages\": ${parameters.messages} }"
      }
    ]
  }'
# Spara connector_id från svaret
```

### Registrera modellen
```bash
curl -X POST "https://localhost:9200/_plugins/_ml/models/_register" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "name": "itemai-gpt-oss-20b",
    "function_name": "remote",
    "description": "GPT-OSS 20B via itemai",
    "connector_id": "<connector_id>"
  }'
# Spara model_id från svaret
```

### Deploya modellen
```bash
curl -X POST "https://localhost:9200/_plugins/_ml/models/<model_id>/_deploy" \
  -u admin:password --insecure
```

### Testa modellen
```bash
curl -X POST "https://localhost:9200/_plugins/_ml/models/<model_id>/_predict" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "parameters": {
      "messages": [
        {"role": "system", "content": "Du är en applikasjonsovervåkingsekspert. Analyser feillogger og gi en kort rapport på norsk."},
        {"role": "user", "content": "NullPointerException i ArticlePageController kl 03:12, 23 forekomster over 8 minutter."}
      ]
    }
  }'
```

### Registrera embedding-modell (för RAG/semantic search)
```bash
# Connector för Nomic Embed på itemai
curl -X POST "https://localhost:9200/_plugins/_ml/connectors/_create" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "name": "itemai-embedding",
    "description": "Nomic Embed via itemai",
    "version": "1",
    "protocol": "http",
    "parameters": {
      "model": "text-embedding-nomic-embed-text-v1.5"
    },
    "actions": [
      {
        "action_type": "predict",
        "method": "POST",
        "url": "http://itemai:1234/v1/embeddings",
        "headers": {
          "Content-Type": "application/json"
        },
        "request_body": "{ \"model\": \"${parameters.model}\", \"input\": ${parameters.input} }"
      }
    ]
  }'
```

### Tillgängliga modeller på itemai

| Modell | Användning | Context |
|--------|-----------|---------|
| openai/gpt-oss-20b | Rapporter, analys | 128K |
| nvidia/nemotron-3-nano | Djupanalys, stora loggvolymer | 262K |
| zai-org/glm-4.7-flash | Sammanfattningar | 200K |
| text-embedding-nomic-embed-text-v1.5 | RAG, semantic search | 2K |

## Alerting — Slack-integration

### Skapa Slack webhook-destination
```bash
curl -X POST "https://localhost:9200/_plugins/_alerting/destinations" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "name": "item-slack",
    "type": "slack",
    "slack": {
      "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    }
  }'
```

### Skapa monitor med AI-genererad rapport till Slack
```bash
# Exempel: Alert vid hög feilfrekvens — skickar till Slack
curl -X POST "https://localhost:9200/_plugins/_alerting/monitors" \
  -u admin:password --insecure \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Hög feilfrekvens",
    "type": "monitor",
    "enabled": true,
    "schedule": {
      "period": { "interval": 5, "unit": "MINUTES" }
    },
    "inputs": [
      {
        "search": {
          "indices": ["enonic-*"],
          "query": {
            "bool": {
              "must": [
                { "match": { "level": "ERROR" } },
                { "range": { "@timestamp": { "gte": "now-5m" } } }
              ]
            }
          }
        }
      }
    ],
    "triggers": [
      {
        "name": "Mange feil",
        "severity": "1",
        "condition": {
          "script": { "source": "ctx.results[0].hits.total.value > 10" }
        },
        "actions": [
          {
            "name": "Slack-varsel",
            "destination_id": "<destination_id>",
            "message_template": {
              "source": "{{ctx.monitor.name}}: {{ctx.results[0].hits.total.value}} feil siste 5 minutter i {{ctx.trigger.name}}"
            }
          }
        ]
      }
    ]
  }'
```

### Alerttyper att sätta upp

| Alert | Trigger | Kanal |
|-------|---------|-------|
| Sajt nere | Uppetidskontroll misslyckas 2x | Slack + e-post |
| Hög feilfrekvens | >10 ERROR/5 min | Slack |
| Långsam responstid | Snitt >2s i 10 min | Slack |
| SSL snart utgånget | <30 dagar kvar | Slack + e-post |
| Disk nästan full | >85% | Slack |

## Felsökning

### OpenSearch startar inte
```bash
# Kontrollera vm.max_map_count
sysctl vm.max_map_count
# Ska vara 262144

# Kontrollera minne (behöver ~8-12 GB)
free -h

# Container-loggar
docker logs opensearch --tail 100
```

### Dashboards visar inga data
```bash
# Finns det index?
curl -X GET "https://localhost:9200/_cat/indices?v" -u admin:password --insecure

# Finns det data?
curl -X GET "https://localhost:9200/_cat/count?v" -u admin:password --insecure

# Kontrollera index pattern i Dashboards UI:
# Stack Management → Index Patterns
```

### Disk full
```bash
# Se indexstorlekar
curl -X GET "https://localhost:9200/_cat/indices?v&s=store.size:desc" \
  -u admin:password --insecure

# Tvinga ISM att köra nu
curl -X POST "https://localhost:9200/_plugins/_ism/retry/enonic-*" \
  -u admin:password --insecure

# Nödlösning — ta bort äldsta index manuellt
curl -X DELETE "https://localhost:9200/enonic-kundnamn-logs-2026.01" \
  -u admin:password --insecure
```
