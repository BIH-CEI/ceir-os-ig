*Deutsche Fassung: [AskMII FDPG](askmii.html)*

AskMII is an MCP server for building queries to the Forschungsdatenportal Gesundheit (FDPG, German Portal for Medical Research Data) of the Medical Informatics Initiative (MII).

### Overview

| Property | Value |
|------------|------|
| Container | `ceir-ask-mii` |
| Port | 2026 |
| KDS version | 2026.0.0 |
| Protocol | MCP (SSE) |

### How it works

AskMII helps with creating structured queries for the FDPG. It knows the MII core data set (Kerndatensatz, KDS) and can:

- Look up available data elements in the KDS
- Formulate structured queries (feasibility queries)
- Suggest combinations of criteria
- Identify codings for query parameters

### KDS (core data set)

The MII core data set defines uniform data structures for medical research. AskMII includes KDS version 2026.0.0 and knows modules such as:

- **Person**: Demographic data
- **Fall** (Case): Facility encounters and department encounters
- **Diagnose** (Diagnosis): ICD-10-GM coded diagnoses
- **Prozedur** (Procedure): OPS-coded procedures
- **Laborbefund** (Laboratory findings): LOINC-coded laboratory values
- **Medikation** (Medication): ATC-coded medications
- **Consent**: Consents

### Usage

#### With Claude Code

AskMII is recognized directly by Claude Code as an MCP server when the SSE endpoint is configured:

```
Use AskMII to create a feasibility query for all patients
with type 2 diabetes mellitus (ICD-10 E11) and HbA1c > 7%.
```

#### With OpenWebUI

Through the MCP Bridge, AskMII becomes available in OpenWebUI automatically. The bridge discovers the AskMII tools at startup and provides them as OpenAI-compatible functions.

### Telemetry

AskMII supports optional telemetry for usage analysis:

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `TELEMETRY_ENABLED` | `true` | Enable/disable telemetry |
| `TELEMETRY_URL` | - | Webhook URL for usage data |
| `TELEMETRY_DATA_DIR` | `/app/data` | Directory for local telemetry data |

Only lightweight metrics are sent: tool name, duration and success (no content).

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `ASKMII_PORT` | `2026` | Host port |
| `ASKMII_PATH` | `../AskMIIAnything` | Build context for Docker |
| `KDS_VERSION` | `2026.0.0` | KDS version |
| `MCP_TRANSPORT` | `sse` | Transport protocol |
| `MCP_HOST` | `0.0.0.0` | Bind address |

### Health Check

```bash
curl -s http://localhost:2026/health
```
