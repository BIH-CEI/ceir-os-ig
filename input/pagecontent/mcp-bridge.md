Die MCP-OpenAI Bridge verbindet lokale LLMs mit den MCP-Tools von CEIR-OS. Sie übersetzt MCP-Tool-Definitionen in das OpenAI Function Calling Format, führt Tool-Aufrufe aus und gibt die Ergebnisse an das Modell zurück. Open WebUI spricht ausschließlich mit der Bridge.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-mcp-bridge` |
| Port | 8000 |
| Framework | FastAPI + Uvicorn |
| Protokoll | OpenAI-kompatible REST API |
| Quelle | `src/mcp_bridge/server.py`, Build durch Compose |

### API-Endpunkte

| Endpunkt | Methode | Beschreibung |
|----------|---------|-------------|
| `/v1/chat/completions` | POST | Chat-Completions mit Tool-Unterstützung, Streaming als SSE-Chunks |
| `/v1/models` | GET | Verfügbare Modelle (Proxy zu Ollama) |
| `/v1/tools` | GET | Entdeckte Tools im OpenAI-Format |
| `/health` | GET | Health Check mit Tool-Anzahl |

### Dynamische Tool-Discovery

Beim Start fragt die Bridge alle konfigurierten MCP-Server über `GET /tools` nach ihren Tools und führt sie später über `POST /call_tool` aus:

| MCP-Server | URL | Tools |
|-----------|-----|-------|
| terminology-mcp | `http://terminology-mcp:3000` | 19 Terminologie-Tools |
| decision-mcp | `http://decision-mcp:3002` | 2 Tools (`map_concept`, `rank_candidates`) |

Die entdeckten Tool-Schemata werden unverändert übernommen, einschließlich Enums. Das `system`-Feld von `search_across_versions` ist seit terminology-mcp 1.1.4 ein Enum der vier BfArM-Systeme, damit kleine Modelle die URLs nicht mehr raten.

Fällt die Discovery aus, greifen eingebaute Fallback-Definitionen (`lookup_code`, `search_common_loinc`, `get_german_label`, `search_across_versions`) über die REST-Endpunkte des Proxys.

### Ausgeschlossene Tools

| Tool | Grund |
|------|-------|
| `validate_biomedical_identifier` | Nicht relevant für typische Abfragen |

`search_codes` war von Februar bis November 2026 ausgeschlossen, weil der Proxy ICD-10-GM damals nicht ohne Versionsangabe durchsuchen konnte und unbegrenzt große Ergebnisse lieferte. Beides ist in terminology-mcp behoben (automatische Versionswahl, Count-Begrenzung), `search_codes` ist wieder die primäre Suche für alle Systeme.

### Auspacken der MCP-Antworten

`/call_tool` liefert das MCP-Format `{"content": [{"type": "text", "text": "<JSON>"}], "isError": false}`. Die Bridge packt den Text aus und parst ihn als JSON, bevor Retry-Logik und Kürzung darauf schauen. Tool-Fehler kommen als HTTP 200 mit `isError` an und werden zu einem expliziten `{"error": ...}` für das Modell.

Bis November 2026 fehlte dieser Schritt. Die Retry-Logik sah deshalb nie Treffer, lief immer bis zum kürzesten Suchwort durch und das Modell bekam den Umschlag als 4000-Zeichen-String. Sichtbar war das als Antworten mit Codes, die das Suchwort gar nicht enthielten.

### Tool-Schleife

Ein Modell darf pro Frage bis zu vier Tool-Runden ausführen, etwa erst suchen, dann nachschlagen, dann verfeinern. Die letzte Runde läuft ohne Tools, damit das Modell antworten muss. Wiederholt ein Modell denselben Aufruf mit denselben Argumenten, endet die Schleife vorzeitig. Tool-Aufrufe im Antworttext (🔧, XML) werden nur geparst, solange Tools angeboten sind. Endet die Schleife nach Tool-Aufrufen ohne Text, fragt die Bridge einmal ohne Tools nach der Antwort. Vorher gab es genau eine Runde; gpt-oss und qwen3 endeten dann mit leerer Antwort, wenn sie einen zweiten Aufruf wollten.

### Smart Search Retry

Bei `search_across_versions` probiert die Bridge den Suchbegriff und dann progressiv kürzere Varianten, bis `uniqueCodes` Treffer enthält:

1. "Diabetes mellitus Typ 2"
2. "Diabetes mellitus Typ"
3. "Diabetes mellitus"
4. "Diabetes"

Seit dem Token-Filter in terminology-mcp 1.1.4 (jedes Wort muss im Display vorkommen, Reihenfolge egal) greift meist schon der erste Versuch.

### Tool Call Parser

Lokale LLMs erzeugen Tool-Aufrufe nicht immer im nativen Format. Die Bridge unterstützt drei Formate:

1. **Natives Ollama Format** über die `tools`-Eigenschaft der Ollama-API (bevorzugt)
2. **XML Format**: `<function=lookup_code><parameter=system>http://snomed.info/sct</parameter><parameter=code>84114007</parameter></function>`
3. **Emoji Format**: `🔧 lookup_code(system=http://snomed.info/sct, code=84114007)`

Die Bridge erkennt die Formate automatisch, führt die Aufrufe aus und entfernt die Formatierung aus der Antwort. Die ausgeführten Aufrufe stehen als 🔧-Zeilen am Anfang jeder Antwort.

### Result Trimming

Um Context-Overflow bei lokalen LLMs zu vermeiden, werden Tool-Ergebnisse gekürzt:

| Tool | Kürzung |
|------|---------|
| `search_codes` | Expansion auf `code`, `display`, `system` reduziert, maximal 20 Codes, plus `total`, `source`, `appliedVersion` |
| `search_across_versions` | neueste Version mit Treffern (10 Codes) plus bis zu 15 eindeutige Codes mit ihren Jahrgängen und der Gesamtzahl. Bis November 2026 kam hier wegen eines falschen Schlüssels keine Codeliste an, die Modelle erfanden ICD-Codes |
| alle anderen | Abschneiden bei 4000 Zeichen |

### System-Prompt

Die Bridge generiert bei jedem Chat einen System-Prompt, der

- alle entdeckten Tools mit Kurzbeschreibung auflistet,
- die CodeSystem-URLs von LOINC, SNOMED CT, ICD-10-GM, OPS, ATC und Alpha-ID wörtlich vorgibt,
- die Rollen festlegt: `search_codes` als primäre Suche für alle Systeme, `search_across_versions` nur für Jahrgangsvergleiche der BfArM-Systeme, `search_common_loinc` erst danach für Nutzungsrang und deutsche Labels,
- Abkürzungen wie EF, IVSd oder PWd vor der Suche in englische LOINC-Begriffe übersetzen lässt,
- das Modell anweist, immer ein Tool aufzurufen und nie Codes aus dem Gedächtnis zu nennen.

### Modelle im Vergleich

Gemessen im November 2026 mit drei Fragen (ICD-10-GM-Suche mit vertauschter Wortreihenfolge, LOINC-Code für die Ejektionsfraktion, LOINC-Code für die Septumdicke) über die Bridge:

| Modell | Tool-Aufrufe | Dauer pro Frage | Einordnung |
|--------|--------------|-----------------|------------|
| `qwen2.5:7b` | ruft Tools zuverlässig, übersetzt Abkürzungen nicht von selbst | 10 bis 20 s | Standard der WebUI |
| `qwen3:14b` | beste Suchbegriffe, übersetzt Abkürzungen, verkettet Aufrufe | 70 bis 140 s | beste Qualität, nahe am 120-s-Timeout der Bridge |
| `gpt-oss:20b` | gute und schnelle Aufrufe | 20 bis 35 s | Kandidat für die WebUI |
| `llama3.1:8b` | rät Codes und schlägt sie dann nach | 10 bis 20 s | ungeeignet |

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `BRIDGE_PORT` | `8000` | Host-Port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | natives Ollama auf dem Host |
| `TERMINOLOGY_URL` | `http://terminology-mcp:3000` | REST-Proxy von terminology-mcp |
| `DECISION_URL` | `http://decision-mcp:3002` | decision-mcp |

Nach Codeänderungen: `docker compose -f docker-compose.terminology.yml build mcp-bridge && docker compose -f docker-compose.terminology.yml up -d --force-recreate mcp-bridge`. Nach einem Update von terminology-mcp die Bridge neu starten, damit sie die Tools erneut entdeckt.

### Health Check

```bash
curl -s http://localhost:8000/health | jq .
```

Antwort:

```json
{
  "status": "ok",
  "service": "mcp-openai-bridge",
  "tools": 20
}
```

Was die Bridge beim Terminologieserver auslöst, steht im Call-Log `logs/terminology-mcp/terminology-calls.jsonl` (Einträge mit `"transport": "rest"` für `/call_tool`, daneben der MCP-Eintrag des Tools mit Quelle und Trefferzahl).
