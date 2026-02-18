Die MCP-OpenAI Bridge verbindet lokale LLMs mit den MCP-Tools von CEIR-OS. Sie übersetzt MCP-Tool-Definitionen in das OpenAI Function Calling Format und führt Tool-Aufrufe automatisch aus.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-mcp-bridge` |
| Port | 8000 |
| Framework | FastAPI + Uvicorn |
| Protokoll | OpenAI-kompatible REST API |

### API-Endpunkte

| Endpunkt | Methode | Beschreibung |
|----------|---------|-------------|
| `/v1/chat/completions` | POST | Chat-Completions mit Tool-Unterstützung |
| `/v1/models` | GET | Verfügbare Modelle (Proxy zu Ollama) |
| `/v1/tools` | GET | Verfügbare Tools auflisten |
| `/health` | GET | Health Check |

### Dynamische Tool-Discovery

Beim Start fragt die Bridge alle konfigurierten MCP-Server nach ihren Tools ab:

| MCP-Server | URL | Tools |
|-----------|-----|-------|
| Terminology MCP | `http://terminology-mcp:3000` | 8 Terminologie-Tools |
| AskMII | `http://ask-mii:2026` | FDPG Query Tools |
| FHIR Spec MCP | `http://fhir-spec:3001` | FHIR-Navigations-Tools |

Die entdeckten Tools werden in das OpenAI Function Format konvertiert und bei jedem Chat-Request an Ollama mitgegeben.

Falls die Discovery fehlschlägt, werden Fallback-Tools verwendet (lookup_code, search_common_loinc, get_german_label, search_across_versions).

### Ausgeschlossene Tools

Folgende Tools werden bei der Discovery übersprungen:

| Tool | Grund |
|------|-------|
| `search_codes` | Probleme mit ICD-10-GM |
| `validate_biomedical_identifier` | Nicht relevant für typische Abfragen |

### Smart Search Retry

Bei `search_across_versions` verwendet die Bridge eine intelligente Retry-Strategie:

1. Zuerst wird der **exakte Suchbegriff** genutzt
2. Bei 0 Treffern wird progressiv das **letzte Wort** entfernt
3. Beispiel: "Diabetes mellitus Typ 2" -> "Diabetes mellitus Typ" -> "Diabetes mellitus" -> "Diabetes"

Dies kompensiert das Problem, dass lokale LLMs oft zu spezifische Suchbegriffe generieren.

### Tool Call Parser

Lokale LLMs erzeugen Tool-Aufrufe nicht immer im nativen Format. Die Bridge unterstützt drei Formate:

#### 1. Natives Ollama Format (bevorzugt)

Das LLM nutzt die `tools`-Eigenschaft der Ollama-API direkt.

#### 2. XML Format

```
<function=lookup_code><parameter=system>http://snomed.info/sct</parameter><parameter=code>84114007</parameter></function>
```

#### 3. Emoji Format

```
🔧 lookup_code(system=http://snomed.info/sct, code=84114007)
```

Die Bridge erkennt diese Formate automatisch, extrahiert die Tool-Aufrufe, führt sie aus und entfernt die Formatierung aus der Antwort.

### Result Trimming

Um Context-Overflow bei lokalen LLMs zu vermeiden, werden Tool-Ergebnisse gekürzt:

| Regel | Wert |
|-------|------|
| Maximale Ergebnisgröße | 4000 Zeichen |
| `search_across_versions` | Nur neueste Version + max. 10 Codes |
| Generisches Trimming | Abschneiden bei Überschreitung des Limits |

### System-Prompt

Die Bridge generiert automatisch einen System-Prompt, der:

- Alle verfügbaren Tools auflistet
- Suchstrategien vorgibt (kurze Suchbegriffe, Hauptwörter bevorzugen)
- Das LLM anweist, immer ein Tool aufzurufen bevor es antwortet
- Das Raten oder Erfinden von Codes verbietet

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `BRIDGE_PORT` | `8000` | Host-Port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | Ollama-Endpunkt |
| `TERMINOLOGY_URL` | `http://terminology-mcp:3000` | Terminology MCP URL |
| `ASKMII_URL` | `http://ask-mii:2026` | AskMII URL |

**Hinweis zu `OLLAMA_URL`**: Der Standard `host.docker.internal` ist für Apple-Metal-GPU-Unterstützung optimiert (Ollama läuft nativ auf dem Host). Für Docker-Ollama (CPU) setze `OLLAMA_URL=http://ollama:11434`.

### Health Check

```bash
curl -s http://localhost:8000/health | jq .
```

Antwort:

```json
{
  "status": "ok",
  "service": "mcp-openai-bridge",
  "tools": 12
}
```
