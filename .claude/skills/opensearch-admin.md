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
