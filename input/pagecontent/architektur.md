Diese Seite beschreibt die System-Architektur von CEIR-OS: Netzwerk, Service-Gruppen, Datenfluesse und persistente Volumes.

### Docker-Netzwerk

Alle Services kommunizieren ueber ein gemeinsames Docker-Netzwerk (`ceir-network`, Bridge-Treiber). Ports werden nur dort auf den Host gemappt, wo ein externer Zugriff noetig ist.

### Service-Gruppen

CEIR-OS laesst sich in drei funktionale Gruppen einteilen:

#### Terminologie-Services

| Service | Aufgabe |
|---------|---------|
| Elasticsearch | Datenbank fuer Snowstorm (intern, kein Host-Port) |
| Snowstorm (8090) | SNOMED CT FHIR Terminologieserver |
| SNOMED Browser (4000) | Web-UI fuer SNOMED CT Exploration |
| Terminology MCP (3000/3002) | Zentraler Terminologie-Zugang (REST + MCP SSE) |

Der Terminology MCP Server buendelt den Zugriff auf:
- **Snowstorm** fuer SNOMED CT (intern via `http://snowstorm:8080/fhir`)
- **MII OntoServer** fuer ICD-10-GM, OPS, ATC (extern via mTLS)
- **Lokale LOINC-Daten** mit deutschen Labels, Panels und Answer Lists

#### LLM- und Chat-Services

| Service | Aufgabe |
|---------|---------|
| Ollama (11434) | Lokaler LLM-Server (Standard: qwen2.5:7b) |
| MCP Bridge (8000) | OpenAI-kompatible API mit Tool-Anbindung |
| Open WebUI (3080) | Chat-Oberflaeche mit Modell-Auswahl |

Die MCP Bridge verbindet lokale LLMs mit Terminologie-Tools. Sie uebersetzt MCP-Tool-Definitionen in OpenAI Function Calling Format und fuehrt Tool-Aufrufe automatisch aus.

#### Forschungs-Services

| Service | Aufgabe |
|---------|---------|
| Zotero Comfort (3001) | Literaturverwaltung (Group + Personal Library) |
| AskMII (2026) | FDPG Query Builder |
| FHIR Spec MCP (8002) | FHIR R4 Spezifikationsnavigator |

### Datenfluss-Uebersicht

```
                         ┌─────────────┐
                         │  Open WebUI  │ :3080
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │  MCP Bridge   │ :8000
                         └──┬───┬───┬───┘
                            │   │   │
              ┌─────────────┘   │   └──────────────┐
              │                 │                   │
       ┌──────▼──────┐  ┌──────▼───────┐  ┌───────▼────────┐
       │   Ollama     │  │ Terminology  │  │  AskMII /      │
       │  (LLM)      │  │   MCP        │  │  FHIR Spec /   │
       │  :11434      │  │  :3000/3002  │  │  Zotero        │
       └──────────────┘  └──┬───┬───┬───┘  └────────────────┘
                            │   │   │
              ┌─────────────┘   │   └──────────────┐
              │                 │                   │
       ┌──────▼──────┐  ┌──────▼───────┐  ┌───────▼────────┐
       │  Snowstorm   │  │ MII OntoServer│  │ Lokale LOINC   │
       │ (SNOMED CT)  │  │ (mTLS, ext.) │  │   Dateien      │
       │  :8090       │  │              │  │                │
       └──────┬───────┘  └──────────────┘  └────────────────┘
              │
       ┌──────▼──────┐
       │Elasticsearch │
       │  (intern)    │
       └──────────────┘
```

**Ablauf einer typischen Anfrage:**

1. Nutzer stellt Frage in **Open WebUI** (z.B. "Was ist der ICD-10 Code fuer Diabetes?")
2. OpenWebUI leitet an **MCP Bridge** weiter (OpenAI-kompatible API)
3. Bridge sendet Anfrage an **Ollama** (lokales LLM)
4. LLM erkennt Tool-Bedarf und erzeugt Tool-Aufruf
5. Bridge fuehrt Tool ueber **Terminology MCP** aus
6. Terminology MCP routet an **Snowstorm** (SNOMED) oder **MII OntoServer** (ICD-10-GM) oder **lokale Dateien** (LOINC)
7. Ergebnis wird zurueck an LLM gegeben, das eine Antwort formuliert

### Persistente Volumes

| Volume | Service | Inhalt |
|--------|---------|--------|
| `elasticsearch-data` | Elasticsearch | SNOMED CT Index-Daten |
| `sct_files` | Snowstorm, Unpacker, Importer | SNOMED CT RF2-Dateien |
| `ollama-data` | Ollama | Heruntergeladene Modelle |
| `openwebui-data` | Open WebUI | Chat-Verlauf und Einstellungen |
| `fhir-cache` | FHIR Spec MCP | FHIR-Spezifikations-Cache |
| `fhir-packages` | FHIR Spec MCP | FHIR-Paket-Cache |
| `askmii-data` | AskMII | Instanz-ID und Session-Logs |

Zusaetzlich werden ueber Host-Bind-Mounts bereitgestellt:
- SNOMED CT Paket (ZIP) via `SNOMED_PACKAGE_PATH`
- mTLS-Zertifikate via `CERT_DIR`
- LOINC-Daten via `LOINC_PATH`
