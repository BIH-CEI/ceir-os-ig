*Deutsche Fassung: [Übersicht](index.html)*

CEIR-OS (Claude-Enabled Interoperability Research Operating Stack) is a Docker-based toolkit for medical interoperability research. It combines terminology servers, AI-assisted tools and literature management in a unified environment that can be run locally.

### What is CEIR-OS?

CEIR-OS provides around 13 services that communicate with each other over a shared Docker network. At its core are:

- **Terminology services**: Snowstorm (SNOMED CT), MII OntoServer (ICD-10-GM, OPS, ATC) and local LOINC data with German labels
- **AI support**: local LLMs via Ollama, an OpenAI-compatible bridge with tool calling and a chat interface (OpenWebUI)
- **Research tools**: Zotero literature management, FDPG Query Builder (AskMII) and FHIR specification navigator

### Service overview

#### Terminology services (local)

| Service | Port | Source | Function |
|---------|------|--------|----------|
| Snowstorm | 8090 | Own container | SNOMED CT FHIR TermServer (v10.8.2) on Elasticsearch |
| SNOMED Browser | 4000 | Own container | Web interface for SNOMED CT |
| Terminology MCP | 3000 / 3002 | Own container | Central terminology access with 19 MCP tools |

The Terminology MCP aggregates three terminology sources:

| CodeSystem | Source | Offline-capable |
|-----------|--------|---------------|
| SNOMED CT | Snowstorm (local FHIR server) | Yes |
| LOINC (+ German labels) | Local files (pre-indexed) | Yes |
| ICD-10-GM, OPS, ATC | MII OntoServer (remote, mTLS) | No |

Details: [Terminology MCP Server](terminologie-mcp-en.html) · [Terminology tools](terminologie-tools-en.html)

#### AI and chat

| Service | Port | Function |
|---------|------|----------|
| Ollama | 11434 | Local LLM server (qwen2.5:7b default) |
| MCP Bridge | 8000 | OpenAI-compatible API with tool routing to MCP servers |
| Open WebUI | 3080 | Chat interface with tool support |

#### Research tools

| Service | Port | Function |
|---------|------|----------|
| AskMII | 2026 | FDPG Query Builder (KDS 2026.0.0) |
| Zotero Comfort | 3001 | Literature management MCP (group + personal library) |
| FHIR Spec MCP | 8002 | FHIR R4 specification navigator |

#### Operations

| Service | Invocation | Function |
|---------|--------|----------|
| Doctor | `docker compose run --rm doctor` | Functional health check of all services (DNS, SNOMED routing, LOINC tools) |

### Quick start

The following must be running or available beforehand (details on the [Installation](installation-en.html) page):

- **Docker Desktop is running.** Otherwise every `docker` command reports `Cannot connect to the Docker daemon`. Check with `docker info`.
- **Ollama is running** as a service (`brew services start ollama`), only needed for the mapping tool.
- **Images are present:** Snowstorm via `docker load`, terminology-mcp in one of the three variants from [Installation, step 3](installation-en.html).
- **LOINC distribution** is unpacked, in any folder.

```bash
# Clone the repository (location up to you)
git clone https://github.com/BIH-CEI/ceir-os.git
cd ceir-os

# Create the configuration
cp .env.example .env
# set at least LOINC_PATH in .env; optionally CERTS_PATH and CERT_PASSPHRASE for the MII OntoServer

# Start the terminology stack
docker info > /dev/null && echo "Docker läuft"
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d snowstorm terminology-mcp

# Check the status
docker compose -f docker-compose.terminology.yml ps
curl -s localhost:3000/health
```

Details on configuration and installation can be found on the [Installation](installation-en.html) page.

### Page index

| Page | Contents |
|-------|--------|
| [Use cases](anwendungsfaelle-en.html) | Who uses CEIR-OS and for what? Roles, use cases and tool assignment |
| [System architecture](architektur-en.html) | Network, service groups, data flows and volumes |
| [Architecture decisions](architekturentscheidungen-en.html) | Why a local Snowstorm? Why our own MCP? 7 documented ADRs |
| [Installation](installation-en.html) | Step-by-step guide |
| [Terminology MCP Server](terminologie-mcp-en.html) | Central terminology access (SNOMED, LOINC, ICD-10-GM, OPS, ATC) |
| [Snowstorm SNOMED CT](snowstorm-en.html) | SNOMED CT server, import and FHIR API |
| [FHIR specification navigator](fhir-spec-mcp-en.html) | Look up FHIR R4 resource definitions |
| [AskMII FDPG](askmii-en.html) | FDPG Query Builder for the German Portal for Medical Research Data (Forschungsdatenportal Gesundheit) |
| [Zotero literature management](zotero-comfort-en.html) | Literature management with PubMed and arXiv integration |
| [MCP-OpenAI Bridge](mcp-bridge-en.html) | Bridge between MCP tools and local LLMs |
| [Local LLMs](lokale-llms-en.html) | Ollama, OpenWebUI and model recommendations |
| [Terminology tools](terminologie-tools-en.html) | The most important tools with parameters and examples |
| [FHIR Mappings](fhir-mappings-en.html) | ConceptMap, StructureMap and mapping workflows |
| [Troubleshooting](troubleshooting-en.html) | Common problems and solutions |
