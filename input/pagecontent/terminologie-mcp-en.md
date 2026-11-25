*Deutsche Fassung: [Terminology MCP Server](terminologie-mcp.html)*

The Terminology MCP Server is the central terminology access point in CEIR-OS. It bundles access to several terminology sources behind a single, uniform interface.

### Overview

| Property | Value |
|------------|------|
| Container | `terminology-mcp` |
| Port 3000 | HTTP REST proxy |
| Port 3002 | MCP SSE endpoint |
| Image | `ghcr.io/bih-cei/terminology-mcp/terminology-mcp:<Tag>` from the `terminology-mcp` repo, tag set via `TERMINOLOGY_MCP_VERSION` in `.env`, can be built locally |

The server provides **two interfaces**:

- **Port 3000 (HTTP REST)**: Classic HTTP endpoints for terminology queries. Used by the MCP Bridge and other services.
- **Port 3002 (MCP SSE)**: Server-Sent Events endpoint for the Model Context Protocol. Used by Claude Code and other MCP clients.

### CodeSystem index

The following table shows all CodeSystems available through CEIR-OS, with the exact `system` URL for FHIR queries.

| CodeSystem | `system` URL (for FHIR) | Source | Versions | Offline |
|-----------|------------------------|--------|-----------|---------|
| SNOMED CT | `http://snomed.info/sct` | Snowstorm (local) | International 2025-12, DE + CH editions | Yes |
| LOINC | `http://loinc.org` | MII OntoServer (main table) + Terminology MCP (complete, local) | OntoServer: v2.77–2.80; local: complete distribution + German labels, panels, answer lists | Yes (local) |
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` | MII OntoServer (remote) | 2009–2025 (17 versions) | No |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` | MII OntoServer (remote) | Several annual versions | No |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` | MII OntoServer (remote) | Several annual versions | No |

> **Tip:** The `system` URL is the value you pass as the `system` parameter to `validate_code`, `lookup_code` and `search_across_versions`. Example: `{"system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm", "code": "E11.9"}`.

#### Which tool for which CodeSystem?

| Tool | SNOMED CT | LOINC | ICD-10-GM | OPS | ATC |
|------|-----------|-------|-----------|-----|-----|
| `validate_code` | x | x | x | x | x |
| `lookup_code` | x | x | x | x | x |
| `search_codes` | x | x | x | x | x |
| `search_common_loinc` | | x | | | |
| `get_german_label` | | x | | | |
| `search_across_versions` | | | x | x | x |
| `list_panels` | | x | | | |
| `get_panel_components` | | x | | | |
| `lookup_loinc_answer_code` | | x | | | |

### Supported CodeSystems by source

The Terminology MCP Server bundles three different terminology sources behind a single, uniform interface. The source determines availability, latency and configuration effort.

#### Local: Snowstorm (own FHIR terminology server)

| CodeSystem | URL | Access |
|-----------|-----|--------|
| SNOMED CT | `http://snomed.info/sct` | FHIR R4 API via Snowstorm (Elasticsearch) |

- **Operation**: Own container (`ceir-snowstorm`), requires Elasticsearch and an SNOMED RF2 import
- **Source**: The SNOMED CT ZIP file is provided within the team (mounted directly as a volume)
- **Loaded editions**: International (900000000000207008), DE edition (11000274103), CH edition (2011000195101)
- **Latency**: Low (local network)
- **Works offline**: Yes

#### Local: File-based (pre-indexed)

| CodeSystem | URL | Access |
|-----------|-----|--------|
| LOINC | `http://loinc.org` | Complete LOINC distribution held locally in the Terminology MCP |

- **Operation**: The complete LOINC distribution is loaded from `LOINC_PATH` at container startup
- **License**: [Regenstrief LOINC License](https://loinc.org/license/) (free of charge after registration)
- **Scope**: Complete LOINC with German translations (where available), panels and answer lists — considerably more than the LOINC main table on the MII terminology server (OntoServer)
- **Latency**: Very low (in-memory)
- **Works offline**: Yes

> **Note:** The MII terminology server (OntoServer) holds only the LOINC main table as a CodeSystem (versions 2.77–2.80). The Terminology MCP, in contrast, holds the complete LOINC distribution locally and uses it to provide access to the German translations (`get_german_label`), panels (`list_panels`, `get_panel_components`) and answer lists (`lookup_loinc_answer_code`). For LOINC queries, the local tools are therefore always preferable.

#### Remote: MII OntoServer, the MII terminology server (mTLS-secured)

| CodeSystem | URL | Access |
|-----------|-----|--------|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` | FHIR R4 API via the MII terminology server (OntoServer) |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` | FHIR R4 API via the MII terminology server (OntoServer) |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` | FHIR R4 API via the MII terminology server (OntoServer) |

- **Operation**: External server of the Medical Informatics Initiative (Medizininformatik-Initiative), accessed via mutual TLS (mTLS)
- **License**: BfArM terminologies, access through MII membership
- **Special feature**: Cross-version search (e.g. ICD-10-GM 2009–2025)
- **Latency**: Medium (network round trip)
- **Works offline**: No — requires a network connection and valid certificates

#### Other CodeSystems on the MII terminology server (OntoServer)

The MII terminology server (OntoServer) provides a total of **1,658 unique CodeSystem URLs** (1,792 entries including versions). The CEIR-OS tools (`validate_code`, `lookup_code`, `search_codes`) can in principle query all of these CodeSystems. The following table shows the most important categories:

| Category | Number of URLs | Examples |
|-----------|-------------|-----------|
| HL7 terminologies | 875 | `http://terminology.hl7.org/CodeSystem/...` (Admit Source, Condition Category, Observation Category etc.) |
| Other (MII, HiGHmed, FDPG etc.) | 425 | MII KDS modules, HiGHmed oncology, FDPG translations, GECCO, NUM |
| HL7 FHIR Core | 277 | `http://hl7.org/fhir/...` (Administrative Gender, Resource Types, Data Types etc.) |
| DE Basisprofil | 37 | `http://fhir.de/CodeSystem/...` (Kontaktebene, ASK, ABDATA, DKGeV, DEÜVAnlagen) |
| BfArM | 24 | ICD-10-GM (17 versions), OPS (16), ATC (8), Alpha-ID (11), plus supplements |
| Ontologies | 16 | HPO, ORPHAcodes, Gene Ontology (GO), HGNC, Sequence Ontology, DICOM, UNII |
| SNOMED CT | 2 | International Edition + MII supplement |
| LOINC | 1 | Versions 2.77–2.80 |
| WHO | 1 | ICD-11 MMS |

> **Note:** The tools `search_across_versions` and `search_common_loinc` are optimized for the main CodeSystems (ICD-10-GM, OPS, ATC and LOINC, respectively). For all other CodeSystems on the OntoServer, you can use `validate_code`, `lookup_code` and `search_codes` with the respective `system` URL.

### Routing logic

The Terminology MCP Server automatically routes requests to the right source:

```
Request ──► detect system URL
            ├── snomed.info/sct     ──► Snowstorm (local, port 8080)
            ├── loinc.org           ──► Local files (in-memory)
            └── fhir.de/CodeSystem/ ──► MII OntoServer (mTLS, remote)
```

### MII terminology server (OntoServer) connection

Access to the MII terminology server (OntoServer) uses mutual TLS (mTLS). This requires the following certificates:

Certificates are provided **at runtime** — never in the image:

| Certificate | Local (volume mount) | CI/CD (env var) |
|-----------|---------------------|-----------------|
| Client certificate | `certs/<Name>.pem` (e.g. `BIH-CEI_Team.pem`) | `CERT_CLIENT_PEM_B64` |
| Private key | `certs/<Name>.key` (same base name) | `CERT_CLIENT_KEY_B64` |
| Root CA | `certs/rootca.pem` | `CERT_ROOT_CA_B64` |
| Intermediate CA | `certs/intermediate.pem` | `CERT_INTERMEDIATE_B64` |

From terminology-mcp 1.1.2 on, the base name of the client certificate is detected automatically (exactly one `<Name>.pem`/`<Name>.key` pair in the certificate directory) or set via `CERT_CLIENT_NAME`. SU-TermServ bundles can therefore be dropped in unchanged when the certificate is replaced; only `CERT_PASSPHRASE` has to be updated along with it.

The `CERT_PASSPHRASE` is obtained through team-internal channels (as an environment variable in both variants).

### Local LOINC data

Local LOINC search offers several advantages over server queries:

- **German labels**: Translations from the official LOINC linguistic variants file
- **Fast search**: Pre-indexed data, no network round trip
- **Panels**: Hierarchical grouping of LOINC codes
- **Answer lists**: Assignment of LOINC answer codes

The data is loaded from the mounted `LOINC_PATH` directory at container startup.

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `SNOWSTORM_URL` | `http://snowstorm:8080/fhir` | Snowstorm FHIR endpoint |
| `SNOWSTORM_SNOMED_VERSION` | `.../version/20261001` | Default edition for SNOMED lookups; must exist on the Snowstorm image |
| `PROXY_SMART_ROUTING` | `true` | REST proxy routes like the MCP tools; `false` = pure OntoServer passthrough |
| `BLAZE_URL` | `http://blaze-full:8080/fhir` | Fallback when the OntoServer is unreachable (LOINC, SNOMED CT International) |
| `CERT_PASSPHRASE` | - | Provided within the team; shell variables override `.env` |
| `CERT_DIR` | `/app/certs` | Directory for certificate files |
| `LOINC_DIR` | `/app/loinc` | Directory for LOINC data |
| `PORT` | `3000` | HTTP REST proxy port |
| `MCP_PORT` | `3002` | MCP SSE port |
| `HOST` | `0.0.0.0` | Bind address |

### Health check

```bash
# HTTP Proxy
curl -s http://localhost:3000/health

# MCP SSE
curl -s http://localhost:3002/health

# Backends: ontoserver / snowstorm / blaze reachable?
curl -s http://localhost:3000/ready | jq .backends
```

Both health endpoints must respond for the container to be considered healthy. Every call via REST or MCP is recorded in the call log `logs/terminology-mcp/terminology-calls.jsonl` with tool, arguments, source, hit count and duration.

### Available tools

The Terminology MCP Server provides 19 tools. A detailed description of the most important tools, with parameters and examples, is on the [Terminology tools](terminologie-tools-en.html) page.
