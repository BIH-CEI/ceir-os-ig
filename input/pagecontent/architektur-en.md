*Deutsche Fassung: [System-Architektur](architektur.html)*

This page describes the system architecture of CEIR-OS: network, service groups, data flows and persistent volumes.

### Docker network

All services communicate over a shared Docker network (`ceir-network`, bridge driver). Ports are mapped to the host only where external access is needed.

### Service groups

CEIR-OS can be divided into three functional groups:

#### Terminology services

| Service | Purpose |
|---------|---------|
| Elasticsearch | Database for Snowstorm (internal, no host port) |
| Snowstorm (8090) | SNOMED CT FHIR terminology server |
| SNOMED Browser (4000) | Web UI for SNOMED CT exploration |
| Terminology MCP (3000/3002) | Central terminology access (REST + MCP SSE) |

The Terminology MCP server bundles access to:
- **Snowstorm** for SNOMED CT (internally via `http://snowstorm:8080/fhir`)
- **MII terminology server (OntoServer)** for ICD-10-GM, OPS, ATC (externally via mTLS)
- **Local LOINC data** with German labels, panels and answer lists

#### LLM and chat services

| Service | Purpose |
|---------|---------|
| Ollama (11434) | Local LLM server (default: qwen2.5:7b) |
| MCP Bridge (8000) | OpenAI-compatible API with tool integration |
| Open WebUI (3080) | Chat interface with model selection |

The MCP Bridge connects local LLMs to terminology tools. It translates MCP tool definitions into the OpenAI function calling format and executes tool calls automatically.

#### Research services

| Service | Purpose |
|---------|---------|
| Zotero Comfort (3001) | Reference management (group + personal library) |
| AskMII (2026) | FDPG query builder |
| FHIR Spec MCP (8002) | FHIR R4 specification navigator |

### Data flow: Claude Code / Claude Desktop (current)

In regular operation, Claude Code or Claude Desktop accesses the services directly via MCP, without a detour through local LLMs or a bridge.

> **Note on the use of Claude:** CEIR-OS works mostly with metadata and specifications that are public or intended for publication (FHIR profiles, terminologies, publication metadata). Claude is **not suitable** for use with proprietary data of external project partners, with patient data or on SharePoint, and must not be used for these.

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
│Elastic-   │  │Local LOINC │
│search     │  │  files     │
│(internal) │  │            │
└───────────┘  └────────────┘
```

**Flow of a typical request:**

1. The user asks a question in Claude Code (e.g. "ICD-10 code for diabetes?")
2. Claude recognizes the need for a tool and calls the matching MCP tool
3. **Terminology MCP** routes to the right source:
   - **Snowstorm** for SNOMED CT (local)
   - **MII terminology server (OntoServer)** for ICD-10-GM, OPS, ATC (remote, mTLS)
   - **Local files** for LOINC (in-memory)
4. The result is returned directly to Claude

### Data flow: Open WebUI + local LLMs

As an alternative to Claude, CEIR-OS can also be operated with local LLMs via Open WebUI. The MCP Bridge translates MCP tools into the OpenAI function calling format.

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

**Features of the MCP Bridge:**
- Dynamic tool discovery from terminology-mcp and decision-mcp
- Unwrapping of the MCP responses, up to four tool rounds per question
- Smart search retry (progressively shorter search terms)
- Emoji/XML tool call parser for local LLMs
- Result trimming (search_codes and search_across_versions structured, otherwise 4000 characters)
- System prompt with CodeSystem URLs and tool roles

**Status:** In use for mapping tests with qwen2.5:7b, qwen3:14b and gpt-oss:20b. Tool-calling reliability depends on the model and is measured in the repo `agentic-terminology-mapping`; see [MCP Bridge](mcp-bridge-en.html) for the model overview.

**Outlook:** In the long term, other models (open source, commercial alternatives) are to be supported as well. This requires robust evaluations (evals) per use case, in particular for tool-calling reliability, terminology correctness and answer quality in German.

### Persistent volumes

| Volume | Service | Content |
|--------|---------|--------|
| `elasticsearch-data` | Elasticsearch | SNOMED CT index data |
| `sct_files` | Snowstorm, Unpacker, Importer | SNOMED CT RF2 files |
| `ollama-data` | Ollama | Downloaded models |
| `openwebui-data` | Open WebUI | Chat history and settings |
| `fhir-cache` | FHIR Spec MCP | FHIR specification cache |
| `fhir-packages` | FHIR Spec MCP | FHIR package cache |
| `askmii-data` | AskMII | Instance ID and session logs |

In addition, the following are provided via host bind mounts:
- SNOMED CT package (ZIP) via `SNOMED_PACKAGE_PATH` (only in the older complete stack `docker-compose.yml`; `docker-compose.terminology.yml` uses the prebuilt image `snowstorm-complete`)
- mTLS certificates from the folder in `CERTS_PATH` (freely selectable), in the container under `/app/certs-host`
- LOINC data via `LOINC_PATH`
- Call log of terminology-mcp to `logs/terminology-mcp/` (REST and MCP, JSONL)
