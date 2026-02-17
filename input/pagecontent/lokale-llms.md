CEIR-OS bietet eine vollstaendige lokale LLM-Infrastruktur: Ollama als Modell-Server, die MCP Bridge fuer Tool-Integration und Open WebUI als Chat-Oberflaeche.

### Ollama Server

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-ollama` |
| Port | 11434 |
| Image | `ollama/ollama:latest` |
| Volume | `ollama-data` (heruntergeladene Modelle) |

Beim ersten Start laedt der Init-Container `ceir-ollama-init` automatisch das Standard-Modell `qwen2.5:7b` herunter.

### Modell-Empfehlungen

| Modell | Groesse | Staerken | Empfehlung |
|--------|---------|----------|-----------|
| `qwen2.5:7b` | 4.7 GB | Gute Balance aus Qualitaet und Geschwindigkeit | **Standard** - wird automatisch geladen |
| `qwen3:14b` | 9.0 GB | Besseres Tool Calling, komplexere Antworten | Empfohlen bei ausreichend RAM/VRAM |
| `llama3.1:8b` | 4.7 GB | Starke allgemeine Faehigkeiten | Alternative zu Qwen |
| `mistral:7b` | 4.1 GB | Schnell, gute europaeische Sprachen | Fuer einfache Abfragen |
| `gemma2:9b` | 5.4 GB | Gutes Sprachverstaendnis | Alternative |

Weitere Modelle koennen manuell geladen werden:

```bash
docker exec ceir-ollama ollama pull qwen3:14b
```

### GPU-Unterstuetzung

#### Apple Metal (macOS)

Fuer optimale Leistung auf macOS mit Apple Silicon sollte Ollama **nativ** auf dem Host laufen (nicht im Container):

1. Installieren Sie Ollama nativ: [ollama.com](https://ollama.com)
2. Setzen Sie in der `.env`:

```env
OLLAMA_URL=http://host.docker.internal:11434
```

Dies ist der **Standard** in CEIR-OS. Die MCP Bridge greift ueber `host.docker.internal` auf den nativen Ollama-Server zu.

#### NVIDIA GPU (Linux)

Fuer NVIDIA-GPUs kommentieren Sie in der `docker-compose.yml` den GPU-Abschnitt ein:

```yaml
ollama:
  # ...
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

Setzen Sie ausserdem:

```env
OLLAMA_URL=http://ollama:11434
```

#### Nur CPU

Wenn keine GPU verfuegbar ist, setzen Sie:

```env
OLLAMA_URL=http://ollama:11434
```

Ollama laeuft dann im CPU-Modus im Container. Die Inferenz ist langsamer, aber funktional.

### Open WebUI

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-webui` |
| Port | 3080 |
| Image | `ghcr.io/open-webui/open-webui:main` |

Open WebUI ist die Chat-Oberflaeche von CEIR-OS. Sie ist so konfiguriert, dass alle Anfragen ueber die MCP Bridge laufen.

#### Wichtige Einstellungen

Die folgenden Einstellungen sind in der `docker-compose.yml` bereits korrekt konfiguriert:

| Einstellung | Wert | Erklaerung |
|------------|------|-----------|
| `ENABLE_OLLAMA_API` | `false` | Direkte Ollama-Verbindung **deaktiviert** |
| `ENABLE_OPENAI_API` | `true` | OpenAI-API aktiviert (via Bridge) |
| `OPENAI_API_BASE_URL` | `http://mcp-bridge:8000/v1` | Zeigt auf die MCP Bridge |
| `OPENAI_API_KEY` | `not-needed` | Kein echter Key noetig |
| `WEBUI_AUTH` | `false` | Keine Authentifizierung (lokal) |
| `WEBUI_NAME` | `CEIR-OS` | Branding |

**Warum Ollama deaktivieren?** Wenn OpenWebUI direkt mit Ollama kommuniziert, werden die MCP-Tools umgangen. Alle Anfragen muessen ueber die MCP Bridge laufen, damit Tool-Aufrufe (Terminologie-Suche, FHIR-Lookup etc.) funktionieren.

#### Empfohlene Chat-Einstellungen in der OpenWebUI-Oberflaeche

| Parameter | Wert | Erklaerung |
|-----------|------|-----------|
| Temperature | 0.3 | Niedrig fuer konsistente Terminologie-Antworten |
| num_ctx | 4096 | Kontextfenster (mehr = langsamer) |
| Top P | 0.9 | Nucleus Sampling |

Diese Einstellungen koennen in OpenWebUI unter "Settings > Models" pro Modell angepasst werden.

### Typischer Arbeitsablauf

1. Oeffnen Sie `http://localhost:3080` im Browser
2. Waehlen Sie ein Modell (z.B. `qwen2.5:7b`)
3. Stellen Sie eine Frage wie: "Was ist der ICD-10 Code fuer Diabetes mellitus Typ 2?"
4. Das LLM erkennt den Tool-Bedarf und die Bridge fuehrt automatisch `search_across_versions` aus
5. Das Ergebnis (z.B. E11.9) wird in die Antwort eingebettet

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `OLLAMA_PORT` | `11434` | Ollama Host-Port |
| `WEBUI_PORT` | `3080` | OpenWebUI Host-Port |
| `BRIDGE_PORT` | `8000` | MCP Bridge Host-Port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | Ollama-Endpunkt fuer die Bridge |
