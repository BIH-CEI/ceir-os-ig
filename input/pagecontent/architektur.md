Diese Seite beschreibt die System-Architektur von CEIR-OS: Netzwerk, Service-Gruppen, Datenflüsse und persistente Volumes.

### Docker-Netzwerk

Alle Services kommunizieren über ein gemeinsames Docker-Netzwerk (`ceir-network`, Bridge-Treiber). Ports werden nur dort auf den Host gemappt, wo ein externer Zugriff nötig ist.

### Service-Gruppen

CEIR-OS lässt sich in drei funktionale Gruppen einteilen:

#### Terminologie-Services

| Service | Aufgabe |
|---------|---------|
| Elasticsearch | Datenbank für Snowstorm (intern, kein Host-Port) |
| Snowstorm (8090) | SNOMED CT FHIR Terminologieserver |
| SNOMED Browser (4000) | Web-UI für SNOMED CT Exploration |
| Terminology MCP (3000/3002) | Zentraler Terminologie-Zugang (REST + MCP SSE) |

Der Terminology MCP Server bündelt den Zugriff auf:
- **Snowstorm** für SNOMED CT (intern via `http://snowstorm:8080/fhir`)
- **MII OntoServer** für ICD-10-GM, OPS, ATC (extern via mTLS)
- **Lokale LOINC-Daten** mit deutschen Labels, Panels und Answer Lists

#### LLM- und Chat-Services

| Service | Aufgabe |
|---------|---------|
| Ollama (11434) | Lokaler LLM-Server (Standard: qwen2.5:7b) |
| MCP Bridge (8000) | OpenAI-kompatible API mit Tool-Anbindung |
| Open WebUI (3080) | Chat-Oberfläche mit Modell-Auswahl |

Die MCP Bridge verbindet lokale LLMs mit Terminologie-Tools. Sie übersetzt MCP-Tool-Definitionen in OpenAI Function Calling Format und führt Tool-Aufrufe automatisch aus.

#### Forschungs-Services

| Service | Aufgabe |
|---------|---------|
| Zotero Comfort (3001) | Literaturverwaltung (Group + Personal Library) |
| AskMII (2026) | FDPG Query Builder |
| FHIR Spec MCP (8002) | FHIR R4 Spezifikationsnavigator |

### Datenfluss: Claude Code / Claude Desktop (aktuell)

Im Regelbetrieb greift Claude Code oder Claude Desktop per MCP direkt auf die Services zu — ohne Umweg über lokale LLMs oder eine Bridge.

> **Hinweis zum Einsatz von Claude:** CEIR-OS arbeitet größtenteils mit öffentlichen oder zur Veröffentlichung vorgesehenen Metadaten und Spezifikationen (FHIR-Profile, Terminologien, Publikationsmetadaten). Für den Einsatz mit proprietären Daten externer Projektpartner, mit Patientendaten oder auf dem SharePoint ist Claude **nicht geeignet** und darf nicht verwendet werden.

```
                    ┌──────────────────────┐
                    │  Claude Desktop /    │
                    │  Claude Code         │
                    └──┬───┬───┬───┬───┬──┘
                       │   │   │   │   │
          MCP SSE      │   │   │   │   │     MCP SSE
       ┌───────────────┘   │   │   │   └──────────────┐
       │          ┌────────┘   │   └────────┐          │
       │          │            │            │          │
┌──────▼──────┐ ┌─▼──────────┐ │ ┌──────────▼─┐ ┌─────▼──────┐
│ Terminology │ │ FHIR Spec  │ │ │  AskMII    │ │  Zotero    │
│   MCP       │ │   MCP      │ │ │  (FDPG)    │ │  Comfort   │
│ :3000/3002  │ │  :8002     │ │ │  :2026     │ │  :3001     │
└──┬───┬───┬──┘ └────────────┘ │ └────────────┘ └────────────┘
   │   │   │                   │
   │   │   └──────────────┐    │ (optional: SNOMED Browser)
   │   │                  │    │
┌──▼───▼──┐  ┌───────────┐│ ┌─▼────────────┐
│Snowstorm │  │MII Onto-  ││ │SNOMED Browser│
│(SNOMED)  │  │Server     ││ │  :4000       │
│ :8090    │  │(mTLS,ext.)││ └──────────────┘
└────┬─────┘  └───────────┘│
     │                     │
┌────▼──────┐  ┌───────────▼┐
│Elastic-   │  │Lokale LOINC│
│search     │  │  Dateien   │
│(intern)   │  │            │
└───────────┘  └────────────┘
```

**Ablauf einer typischen Anfrage:**

1. Nutzer stellt Frage in Claude Code (z.B. "ICD-10 Code für Diabetes?")
2. Claude erkennt den Tool-Bedarf und ruft das passende MCP-Tool auf
3. **Terminology MCP** routet an die richtige Quelle:
   - **Snowstorm** für SNOMED CT (lokal)
   - **MII OntoServer** für ICD-10-GM, OPS, ATC (remote, mTLS)
   - **Lokale Dateien** für LOINC (In-Memory)
4. Ergebnis wird direkt an Claude zurückgegeben

### Datenfluss: Open WebUI + lokale LLMs (in Entwicklung)

Als Alternative zu Claude kann CEIR-OS auch mit lokalen LLMs über Open WebUI betrieben werden. Die MCP Bridge übersetzt dabei MCP-Tools ins OpenAI Function Calling Format.

```
                         ┌─────────────┐
                         │  Open WebUI  │ :3080
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │  MCP Bridge   │ :8000
                         └──┬───────┬───┘
                            │       │
                   ┌────────┘       └────────┐
                   │                         │
            ┌──────▼──────┐          ┌───────▼────────┐
            │   Ollama     │          │ Terminology /  │
            │  (LLM)      │          │ AskMII / FHIR  │
            │  :11434      │          │ Spec / Zotero  │
            └──────────────┘          └────────────────┘
```

**Features der MCP Bridge:**
- Dynamische Tool-Discovery von allen MCP-Servern
- Smart Search Retry (progressiv kürzere Suchbegriffe)
- Emoji/XML Tool Call Parser für lokale LLMs
- Result Trimming (max 4000 Zeichen für begrenzte Kontextfenster)

**Status:** Funktionsfähig mit qwen3:14b. Modell-Qualität und Tool-Calling-Zuverlässigkeit sind noch nicht auf Claude-Niveau — siehe [MCP Bridge](mcp-bridge.html) für Details.

**Ausblick:** Langfristig sollen auch andere Modelle (Open Source, kommerzielle Alternativen) unterstützt werden. Voraussetzung dafür sind belastbare Evaluationen (Evals) pro Anwendungsfall — insbesondere für Tool-Calling-Zuverlässigkeit, Terminologie-Korrektheit und Antwortqualität auf Deutsch.

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

Zusätzlich werden über Host-Bind-Mounts bereitgestellt:
- SNOMED CT Paket (ZIP) via `SNOMED_PACKAGE_PATH`
- mTLS-Zertifikate via `CERT_DIR`
- LOINC-Daten via `LOINC_PATH`
