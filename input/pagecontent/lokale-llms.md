CEIR-OS bietet eine vollständige lokale LLM-Infrastruktur: Ollama als Modell-Server, die MCP Bridge für Tool-Integration und Open WebUI als Chat-Oberfläche.

### Ollama Server

Im aktuellen Stack (`docker-compose.terminology.yml`) läuft Ollama **nativ auf dem Host** auf Port 11434, nicht im Container. Auf Apple Silicon ist das die einzige Möglichkeit, die Metal-GPU zu nutzen. Die Bridge erreicht Ollama über `host.docker.internal`. Modelle werden mit `ollama pull <modell>` geladen, der ältere Komplettstack (`docker-compose.yml`) enthält alternativ den Container `ceir-ollama` mit Init-Container, der `qwen2.5:7b` automatisch lädt.

### Modell-Empfehlungen

Gemessen im November 2026 über die Bridge mit Terminologie-Fragen (Details auf der Seite [MCP Bridge](mcp-bridge.html)):

| Modell | Größe | Tool-Calling | Dauer pro Frage | Empfehlung |
|--------|-------|--------------|-----------------|------------|
| `qwen2.5:7b` | 4.7 GB | zuverlässig, übersetzt Abkürzungen nicht von selbst | 10 bis 20 s | **Standard** der WebUI |
| `qwen3:14b` | 9.0 GB | beste Suchbegriffe, verkettet Aufrufe | 70 bis 140 s | beste Qualität, langsam |
| `gpt-oss:20b` | 14 GB | gute und schnelle Aufrufe | 20 bis 35 s | Kandidat für die WebUI, braucht viel RAM |
| `llama3.1:8b` | 4.7 GB | rät Codes und schlägt sie dann nach | 10 bis 20 s | ungeeignet |

Große Modelle verdrängen den nativen Open-Jev-Server in den Swap, dann laufen Tool-Aufrufe in das 120-Sekunden-Timeout der Bridge. Deshalb sind in der Compose die Hintergrundaufgaben der WebUI (Titel, Tags, Suchanfragen) abgeschaltet und `TASK_MODEL` auf `qwen2.5:7b` gesetzt.

Modelle laden:

```bash
ollama pull qwen3:14b
```

### GPU-Unterstützung

#### Apple Metal (macOS)

Für optimale Leistung auf macOS mit Apple Silicon sollte Ollama **nativ** auf dem Host laufen (nicht im Container):

1. Installiere Ollama nativ: [ollama.com](https://ollama.com)
2. Setze in der `.env`:

```env
OLLAMA_URL=http://host.docker.internal:11434
```

Dies ist der **Standard** in CEIR-OS. Die MCP Bridge greift über `host.docker.internal` auf den nativen Ollama-Server zu.

#### NVIDIA GPU (Linux)

Für NVIDIA-GPUs kommentiere in der `docker-compose.yml` den GPU-Abschnitt ein:

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

Setze außerdem:

```env
OLLAMA_URL=http://ollama:11434
```

#### Nur CPU

Wenn keine GPU verfügbar ist, setze:

```env
OLLAMA_URL=http://ollama:11434
```

Ollama läuft dann im CPU-Modus im Container. Die Inferenz ist langsamer, aber funktional.

### Open WebUI

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-webui` |
| Port | 3080 |
| Image | `ghcr.io/open-webui/open-webui:main` |

Open WebUI ist die Chat-Oberfläche von CEIR-OS. Sie ist so konfiguriert, dass alle Anfragen über die MCP Bridge laufen.

#### Wichtige Einstellungen

Die folgenden Einstellungen sind in `docker-compose.terminology.yml` bereits korrekt konfiguriert:

| Einstellung | Wert | Erklärung |
|------------|------|-----------|
| `ENABLE_OLLAMA_API` | `false` | Direkte Ollama-Verbindung **deaktiviert** |
| `ENABLE_OPENAI_API` | `true` | OpenAI-API aktiviert (via Bridge) |
| `OPENAI_API_BASE_URL` | `http://mcp-bridge:8000/v1` | Zeigt auf die MCP Bridge |
| `OPENAI_API_KEY` | `not-needed` | Kein echter Key nötig |
| `WEBUI_AUTH` | `false` | Keine Authentifizierung (lokal) |
| `WEBUI_NAME` | `CEIR-OS` | Branding |

**Warum Ollama deaktivieren?** Wenn OpenWebUI direkt mit Ollama kommuniziert, werden die MCP-Tools umgangen. Alle Anfragen müssen über die MCP Bridge laufen, damit Tool-Aufrufe (Terminologie-Suche, FHIR-Lookup etc.) funktionieren.

#### Empfohlene Chat-Einstellungen in der OpenWebUI-Oberfläche

| Parameter | Wert | Erklärung |
|-----------|------|-----------|
| Temperature | 0.3 | Niedrig für konsistente Terminologie-Antworten |
| num_ctx | 4096 | Kontextfenster (mehr = langsamer) |
| Top P | 0.9 | Nucleus Sampling |

Diese Einstellungen können in OpenWebUI unter "Settings > Models" pro Modell angepasst werden.

### Typischer Arbeitsablauf

1. Öffne `http://localhost:3080` im Browser
2. Wähle ein Modell (z.B. `qwen2.5:7b`)
3. Stelle eine Frage wie: "Was ist der ICD-10 Code für Diabetes mellitus Typ 2?"
4. Das LLM erkennt den Tool-Bedarf, die Bridge führt `search_codes` oder `search_across_versions` aus, bei Bedarf mehrere Runden
5. Das Ergebnis (z.B. E11.9) wird in die Antwort eingebettet, die 🔧-Zeilen am Anfang zeigen die Aufrufe
6. Was beim Terminologieserver ankam, steht in `logs/terminology-mcp/terminology-calls.jsonl`

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `OLLAMA_PORT` | `11434` | Ollama Host-Port |
| `WEBUI_PORT` | `3080` | OpenWebUI Host-Port |
| `BRIDGE_PORT` | `8000` | MCP Bridge Host-Port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | Ollama-Endpunkt für die Bridge |
