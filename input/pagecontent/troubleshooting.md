Diese Seite beschreibt häufige Probleme beim Betrieb von CEIR-OS und deren Lösungen.

### Snowstorm startet nicht

**Symptom:** Der Container `ceir-snowstorm` startet wiederholt neu oder bleibt im Status "starting".

**Ursache 1: Elasticsearch hat nicht genug Speicher**

```bash
# Elasticsearch-Logs prüfen
docker logs ceir-elasticsearch 2>&1 | tail -20
```

Lösung: `ES_JAVA_OPTS` in der `.env` anpassen:

```env
ES_JAVA_OPTS="-Xms2g -Xmx2g"
```

Danach neu starten:

```bash
docker compose down
docker compose up -d
```

**Ursache 2: Elasticsearch ist noch nicht healthy**

Snowstorm wartet auf den Elasticsearch Health Check. Prüfe:

```bash
curl -s http://localhost:9200/_cluster/health | jq .status
```

Der Status muss `green` oder `yellow` sein.

**Ursache 3: SNOMED-Import fehlgeschlagen**

```bash
docker logs ceir-snomed-importer
```

Falls der Import abgebrochen wurde, lösche die Marker-Datei und starte neu:

```bash
docker compose down
docker volume rm ceir-os_sct_files
docker compose up -d
```

### Snowstorm DNS-Auflösung fehlgeschlagen

**Symptom:** Der Terminology MCP Server kann Snowstorm nicht erreichen. `lookup_code` für SNOMED CT schlägt fehl, obwohl Snowstorm läuft.

**Ursache:** Wenn Snowstorm einzeln neu gestartet wird (z.B. `docker restart ceir-snowstorm`), verliert der Container seinen DNS-Alias im Docker-Netzwerk. Andere Container können `snowstorm` dann nicht mehr auflösen.

**Diagnose:**

```bash
# Doctor-Service ausführen — prüft DNS und alle Routen
docker compose run --rm doctor
```

**Lösung:** Snowstorm und abhängige Services über Docker Compose neu erstellen:

```bash
docker compose up -d --force-recreate snowstorm terminology-mcp
```

> **Wichtig:** `docker restart` reicht nicht — es muss `--force-recreate` sein, damit Docker die DNS-Einträge im Netzwerk neu registriert.

### SNOMED-Import dauert sehr lange

Der initiale Import kann je nach Paketgröße 10-30 Minuten dauern. Fortschritt prüfen:

```bash
docker logs -f ceir-snomed-importer
```

Während des Imports ist Snowstorm bereits gestartet, aber noch nicht vollständig funktional.

### MII OntoServer nicht erreichbar

**Symptom:** `search_across_versions` liefert Fehler für ICD-10-GM, OPS oder ATC.

**Ursache 1: mTLS-Zertifikate fehlen oder sind ungültig**

```bash
# Terminology MCP Logs prüfen
docker logs ceir-terminology-mcp 2>&1 | grep -i cert
```

Prüfe:
- Sind die Zertifikat-Dateien im `CERTS_PATH`-Verzeichnis vorhanden?
- Ist `CERT_PASSPHRASE` korrekt gesetzt?
- Sind die Base64-kodierten Werte (falls verwendet) vollständig?

**Ursache 2: Netzwerkprobleme**

Der MII OntoServer ist ein externer Dienst. Prüfe die Erreichbarkeit:

```bash
docker exec ceir-terminology-mcp curl -k https://mii-termserv.de/fhir/metadata
```

### Tools funktionieren nicht in OpenWebUI

**Symptom:** Das LLM antwortet ohne Tool-Aufrufe, Codes werden geraten.

**Ursache 1: Ollama ist direkt verbunden (Bridge umgangen)**

Prüfe die OpenWebUI-Konfiguration:

```bash
docker inspect ceir-webui | jq '.[0].Config.Env' | grep -i ollama
```

`ENABLE_OLLAMA_API` muss `false` sein. Wenn es `true` ist, kommuniziert OpenWebUI direkt mit Ollama und umgeht die MCP Bridge.

Lösung: Stelle sicher, dass in der `docker-compose.yml`:

```yaml
- ENABLE_OLLAMA_API=false
- ENABLE_OPENAI_API=true
- OPENAI_API_BASE_URL=http://mcp-bridge:8000/v1
```

**Ursache 2: MCP Bridge hat keine Tools entdeckt**

```bash
curl -s http://localhost:8000/health | jq .
```

Wenn `tools: 0`, sind die MCP-Server nicht erreichbar. Prüfe die Logs:

```bash
docker logs ceir-mcp-bridge 2>&1 | grep -i discover
```

**Ursache 3: Modell unterstützt kein Tool Calling**

Nicht alle Modelle unterstützen Tool Calling zuverlässig. Empfohlene Modelle:

| Modell | Tool Calling |
|--------|-------------|
| `qwen2.5:7b` | Gut |
| `qwen3:14b` | Sehr gut |
| `llama3.1:8b` | Mäßig |

### LOINC-Suche liefert keine deutschen Labels

**Symptom:** `search_common_loinc` oder `get_german_label` geben keine deutschen Übersetzungen zurück.

**Ursache: LOINC-Daten nicht gemountet**

Prüfe:

```bash
docker exec ceir-terminology-mcp ls /app/loinc/
```

Das Verzeichnis muss die LOINC-Distribution enthalten. Prüfe den `LOINC_PATH` in der `.env`:

```env
LOINC_PATH=/pfad/zu/Loinc_2.81
```

### Docker-Speicherprobleme

**Symptom:** Container werden mit "OOMKilled" beendet.

Lösung: Docker-Ressourcen erhöhen (Docker Desktop > Settings > Resources):

| Ressource | Minimum | Empfohlen |
|-----------|---------|-----------|
| RAM | 8 GB | 16 GB |
| Festplatte | 20 GB | 50 GB |
| CPUs | 2 | 4 |

Für Elasticsearch spezifisch:

```env
ES_JAVA_OPTS="-Xms1g -Xmx1g"
```

### Port-Konflikte

**Symptom:** Container startet nicht wegen "port already in use".

Prüfe, welcher Prozess den Port belegt:

```bash
lsof -i :8090  # Snowstorm
lsof -i :3000  # Terminology MCP
lsof -i :8000  # MCP Bridge
```

Lösung: Ändere den Port in der `.env`:

```env
SNOWSTORM_PORT=9090
TERMINOLOGY_PROXY_PORT=3100
BRIDGE_PORT=8001
```

### Health Checks für alle Services

CEIR-OS enthält einen integrierten **Doctor-Service**, der alle Services, DNS-Auflösung und funktionale Routen prüft:

```bash
docker compose run --rm doctor
```

Der Doctor führt 20 Checks aus:

| Kategorie | Was wird geprüft |
|-----------|-----------------|
| DNS-Auflösung | Alle 5 Service-Hostnamen im Docker-Netzwerk |
| Elasticsearch | Cluster Health |
| Snowstorm (direkt) | FHIR Metadata, CodeSystems, Concept Lookup, FHIR CodeSystem Lookup |
| SNOMED Routing | Terminology Proxy → Snowstorm (POST /lookup mit echten SNOMED-Codes) |
| LOINC Local Tools | Deutsche Labels (Körpertemperatur, Kreatinin), Panel-Index |
| Service Health | Proxy HTTP, MCP SSE, Snowstorm-Verbindung, LOINC-Panels geladen |
| MCP Bridge | Health Check |

Alternativ gibt es das Host-seitige Script `./doctor.sh`, das zusätzlich Container-Status und Cross-Service-Konnektivität von außen prüft.

Für einzelne Services:

```bash
# Snowstorm
curl -s http://localhost:8090/fhir/metadata | jq .software

# Terminology MCP
curl -s http://localhost:3002/health | jq .

# MCP Bridge
curl -s http://localhost:8000/health | jq .
```

### Vollständiger Neustart

Falls nichts anderes hilft:

```bash
# Alle Container stoppen und entfernen
docker compose down

# Optional: Volumes löschen (ACHTUNG: SNOMED-Import muss wiederholt werden!)
docker compose down -v

# Neu starten
docker compose up -d

# Logs beobachten
docker compose logs -f
```
