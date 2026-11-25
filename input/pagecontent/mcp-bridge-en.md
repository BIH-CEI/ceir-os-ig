*Deutsche Fassung: [MCP-OpenAI Bridge](mcp-bridge.html)*

The MCP-OpenAI Bridge connects local LLMs with the MCP tools of CEIR-OS. It translates MCP tool definitions into the OpenAI function calling format, executes tool calls and returns the results to the model. Open WebUI talks exclusively to the bridge.

### Overview

| Property | Value |
|------------|------|
| Container | `ceir-mcp-bridge` |
| Port | 8000 |
| Framework | FastAPI + Uvicorn |
| Protocol | OpenAI-compatible REST API |
| Source | `src/mcp_bridge/server.py`, built by Compose |

### API Endpoints

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/v1/chat/completions` | POST | Chat completions with tool support, streaming as SSE chunks |
| `/v1/models` | GET | Available models (proxy to Ollama) |
| `/v1/tools` | GET | Discovered tools in OpenAI format |
| `/health` | GET | Health check with tool count |

### Dynamic Tool Discovery

At startup the bridge asks all configured MCP servers for their tools via `GET /tools` and later executes them via `POST /call_tool`:

| MCP server | URL | Tools |
|-----------|-----|-------|
| terminology-mcp | `http://terminology-mcp:3000` | 19 terminology tools |
| decision-mcp | `http://decision-mcp:3002` | 2 tools (`map_concept`, `rank_candidates`) |

The discovered tool schemas are taken over unchanged, including enums. Since terminology-mcp 1.1.4, the `system` field of `search_across_versions` is an enum of the four BfArM systems, so that small models no longer guess the URLs.

If discovery fails, built-in fallback definitions (`lookup_code`, `search_common_loinc`, `get_german_label`, `search_across_versions`) take over via the proxy's REST endpoints.

### Excluded Tools

| Tool | Reason |
|------|-------|
| `validate_biomedical_identifier` | Not relevant for typical queries |

`search_codes` was excluded from February to November 2026 because at that time the proxy could not search ICD-10-GM without a version and returned results of unlimited size. Both issues are fixed in terminology-mcp (automatic version selection, count limit); `search_codes` is again the primary search for all systems.

### Unpacking the MCP Responses

`/call_tool` returns the MCP format `{"content": [{"type": "text", "text": "<JSON>"}], "isError": false}`. The bridge unpacks the text and parses it as JSON before the retry logic and trimming look at it. Tool errors arrive as HTTP 200 with `isError` and are turned into an explicit `{"error": ...}` for the model.

Until November 2026 this step was missing. As a result, the retry logic never saw any hits, always ran down to the shortest search word, and the model received the envelope as a 4000-character string. This showed up as answers with codes that did not even contain the search word.

### Tool Loop

A model may run up to four tool rounds per question, for example first search, then look up, then refine. The last round runs without tools so that the model has to answer. If a model repeats the same call with the same arguments, the loop ends early. Tool calls in the answer text (🔧, XML) are parsed only as long as tools are offered. If the loop ends after tool calls without text, the bridge asks once, without tools, for the answer. Previously there was exactly one round; gpt-oss and qwen3 then ended with an empty answer when they wanted a second call.

### Smart Search Retry

For `search_across_versions` the bridge tries the search term and then progressively shorter variants until `uniqueCodes` contains hits:

1. "Diabetes mellitus Typ 2"
2. "Diabetes mellitus Typ"
3. "Diabetes mellitus"
4. "Diabetes"

Since the token filter in terminology-mcp 1.1.4 (every word must occur in the display, in any order), the first attempt usually succeeds.

### Tool Call Parser

Local LLMs do not always produce tool calls in the native format. The bridge supports three formats:

1. **Native Ollama format** via the `tools` property of the Ollama API (preferred)
2. **XML format**: `<function=lookup_code><parameter=system>http://snomed.info/sct</parameter><parameter=code>84114007</parameter></function>`
3. **Emoji format**: `🔧 lookup_code(system=http://snomed.info/sct, code=84114007)`

The bridge detects the formats automatically, executes the calls and removes the formatting from the answer. The executed calls appear as 🔧 lines at the beginning of each answer.

### Result Trimming

To avoid context overflow in local LLMs, tool results are trimmed:

| Tool | Trimming |
|------|---------|
| `search_codes` | Expansion reduced to `code`, `display`, `system`, at most 20 codes, plus `total`, `source`, `appliedVersion` |
| `search_across_versions` | newest version with hits (10 codes) plus up to 15 unique codes with their release years and the total count. Until November 2026 no code list arrived here because of a wrong key, and the models invented ICD codes |
| all others | Cut off at 4000 characters |

### System Prompt

For every chat the bridge generates a system prompt that

- lists all discovered tools with a short description,
- prescribes the CodeSystem URLs of LOINC, SNOMED CT, ICD-10-GM, OPS, ATC and Alpha-ID verbatim,
- defines the roles: `search_codes` as the primary search for all systems, `search_across_versions` only for comparing release years of the BfArM systems, `search_common_loinc` only afterwards for usage rank and German labels,
- has abbreviations such as EF, IVSd or PWd translated into English LOINC terms before the search,
- instructs the model to always call a tool and never to state codes from memory.

### Models Compared

Measured in November 2026 through the bridge with three questions (ICD-10-GM search with swapped word order, LOINC code for the ejection fraction, LOINC code for the septal thickness):

| Model | Tool calls | Time per question | Assessment |
|--------|--------------|-----------------|------------|
| `qwen2.5:7b` | calls tools reliably, does not translate abbreviations on its own | 10 to 20 s | WebUI default |
| `qwen3:14b` | best search terms, translates abbreviations, chains calls | 70 to 140 s | best quality, close to the bridge's 120 s timeout |
| `gpt-oss:20b` | good and fast calls | 20 to 35 s | candidate for the WebUI |
| `llama3.1:8b` | guesses codes and then looks them up | 10 to 20 s | unsuitable |

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `BRIDGE_PORT` | `8000` | Host port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | native Ollama on the host |
| `TERMINOLOGY_URL` | `http://terminology-mcp:3000` | REST proxy of terminology-mcp |
| `DECISION_URL` | `http://decision-mcp:3002` | decision-mcp |

After code changes: `docker compose -f docker-compose.terminology.yml build mcp-bridge && docker compose -f docker-compose.terminology.yml up -d --force-recreate mcp-bridge`. After an update of terminology-mcp, restart the bridge so that it discovers the tools again.

### Health Check

```bash
curl -s http://localhost:8000/health | jq .
```

Response:

```json
{
  "status": "ok",
  "service": "mcp-openai-bridge",
  "tools": 20
}
```

What the bridge triggers on the terminology server is recorded in the call log `logs/terminology-mcp/terminology-calls.jsonl` (entries with `"transport": "rest"` for `/call_tool`, next to them the MCP entry of the tool with source and hit count).
