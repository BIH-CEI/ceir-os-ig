CEIR-OS (Claude-Enabled Interoperability Research Operating Stack) ist ein Docker-basiertes Toolkit fuer die medizinische Interoperabilitaetsforschung. Es kombiniert Terminologieserver, KI-gestuetzte Werkzeuge und Literaturverwaltung in einer einheitlichen, lokal betreibbaren Umgebung.

### Was ist CEIR-OS?

CEIR-OS stellt rund 13 Services bereit, die ueber ein gemeinsames Docker-Netzwerk miteinander kommunizieren. Im Zentrum stehen:

- **Terminologie-Services**: Snowstorm (SNOMED CT), MII OntoServer (ICD-10-GM, OPS, ATC) und lokale LOINC-Daten mit deutschen Labels
- **KI-Unterstuetzung**: Lokale LLMs via Ollama, eine OpenAI-kompatible Bridge mit Tool-Calling und eine Chat-Oberflaeche (OpenWebUI)
- **Forschungswerkzeuge**: Zotero-Literaturverwaltung, FDPG Query Builder (AskMII) und FHIR-Spezifikationsnavigator

### Service-Uebersicht

#### Terminologie-Services (lokal)

| Service | Port | Quelle | Funktion |
|---------|------|--------|----------|
| Snowstorm | 8090 | Eigener Container | SNOMED CT FHIR TermServer (v10.8.2) auf Elasticsearch |
| SNOMED Browser | 4000 | Eigener Container | Web-Oberflaeche fuer SNOMED CT |
| Terminology MCP | 3000 / 3002 | Eigener Container | Zentraler Terminologie-Zugang mit 8 MCP-Tools |

Der Terminology MCP aggregiert drei Terminologie-Quellen:

| CodeSystem | Quelle | Offline-faehig |
|-----------|--------|---------------|
| SNOMED CT | Snowstorm (lokaler FHIR Server) | Ja |
| LOINC (+ deutsche Labels) | Lokale Dateien (vorindexiert) | Ja |
| ICD-10-GM, OPS, ATC | MII OntoServer (remote, mTLS) | Nein |

Details: [Terminology MCP Server](terminologie-mcp.html) · [Terminologie-Tools](terminologie-tools.html)

#### KI und Chat

| Service | Port | Funktion |
|---------|------|----------|
| Ollama | 11434 | Lokaler LLM-Server (qwen2.5:7b Standard) |
| MCP Bridge | 8000 | OpenAI-kompatible API mit Tool-Routing zu MCP-Servern |
| Open WebUI | 3080 | Chat-Oberflaeche mit Tool-Unterstuetzung |

#### Forschungswerkzeuge

| Service | Port | Funktion |
|---------|------|----------|
| AskMII | 2026 | FDPG Query Builder (KDS 2026.0.0) |
| Zotero Comfort | 3001 | Literaturverwaltung MCP (Gruppen- + persoenliche Bibliothek) |
| FHIR Spec MCP | 8002 | FHIR R4 Spezifikationsnavigator |

### Schnellstart

```bash
# Repository klonen
git clone https://github.com/BIH-CEI/ceir-os.git
cd ceir-os

# Konfiguration erstellen
cp .env.example .env
# .env anpassen (Pfade, Zertifikate, API-Keys)

# Stack starten
docker compose up -d

# Status pruefen
docker compose ps
```

Details zur Konfiguration und Installation finden sich auf der Seite [Installation](installation.html).

### Seitenverzeichnis

| Seite | Inhalt |
|-------|--------|
| [System-Architektur](architektur.html) | Netzwerk, Service-Gruppen, Datenfluesse und Volumes |
| [Installation](installation.html) | Schritt-fuer-Schritt-Anleitung |
| [Terminology MCP Server](terminologie-mcp.html) | Zentraler Terminologie-Zugang (SNOMED, LOINC, ICD-10-GM, OPS, ATC) |
| [Snowstorm SNOMED CT](snowstorm.html) | SNOMED CT Server, Import und FHIR API |
| [FHIR Spezifikations-Navigator](fhir-spec-mcp.html) | FHIR R4 Ressourcen-Definitionen nachschlagen |
| [AskMII FDPG](askmii.html) | FDPG Query Builder fuer das Forschungsdatenportal Gesundheit |
| [Zotero Literaturverwaltung](zotero-comfort.html) | Literaturverwaltung mit PubMed- und arXiv-Integration |
| [MCP-OpenAI Bridge](mcp-bridge.html) | Bridge zwischen MCP-Tools und lokalen LLMs |
| [Lokale LLMs](lokale-llms.html) | Ollama, OpenWebUI und Modell-Empfehlungen |
| [Terminologie-Tools](terminologie-tools.html) | Alle 8 Tools mit Parametern und Beispielen |
| [FHIR Mappings](fhir-mappings.html) | ConceptMap, StructureMap und Mapping-Workflows |
| [Fehlerbehebung](troubleshooting.html) | Haeufige Probleme und Loesungen |
