CEIR-OS (Claude-Enabled Interoperability Research Operating Stack) ist ein Docker-basiertes Toolkit fuer die medizinische Interoperabilitaetsforschung. Es kombiniert Terminologieserver, KI-gestuetzte Werkzeuge und Literaturverwaltung in einer einheitlichen, lokal betreibbaren Umgebung.

### Was ist CEIR-OS?

CEIR-OS stellt rund 13 Services bereit, die ueber ein gemeinsames Docker-Netzwerk miteinander kommunizieren. Im Zentrum stehen:

- **Terminologie-Services**: Snowstorm (SNOMED CT), MII OntoServer (ICD-10-GM, OPS, ATC) und lokale LOINC-Daten mit deutschen Labels
- **KI-Unterstuetzung**: Lokale LLMs via Ollama, eine OpenAI-kompatible Bridge mit Tool-Calling und eine Chat-Oberflaeche (OpenWebUI)
- **Forschungswerkzeuge**: Zotero-Literaturverwaltung, FDPG Query Builder (AskMII) und FHIR-Spezifikationsnavigator

### Service-Uebersicht

| Service | Container | Port | Funktion |
|---------|-----------|------|----------|
| Elasticsearch | ceir-elasticsearch | (intern) | Datenbank fuer Snowstorm |
| Snowstorm | ceir-snowstorm | 8090 | SNOMED CT FHIR Terminologieserver (v10.8.2) |
| SNOMED Browser | ceir-browser | 4000 | Web-Oberflaeche fuer SNOMED CT |
| Terminology MCP | ceir-terminology-mcp | 3000 / 3002 | HTTP-Proxy + MCP SSE (SNOMED, LOINC, ICD-10-GM, OPS, ATC) |
| AskMII | ceir-ask-mii | 2026 | FDPG Query Builder MCP |
| Zotero Comfort | ceir-zotero-comfort | 3001 | Literaturverwaltung MCP (Dual-Library) |
| FHIR Spec MCP | ceir-fhir-spec-mcp | 8002 | FHIR R4 Spezifikationsnavigator |
| Ollama | ceir-ollama | 11434 | Lokaler LLM-Server |
| MCP Bridge | ceir-mcp-bridge | 8000 | OpenAI-kompatible API mit Tool-Anbindung |
| Open WebUI | ceir-webui | 3080 | Chat-Oberflaeche |

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
