*Deutsche Fassung: [Lokale LLMs](lokale-llms.html)*

CEIR-OS provides a complete local LLM infrastructure: Ollama as the model server, the MCP Bridge for tool integration and Open WebUI as the chat interface.

### Ollama Server

In the current stack (`docker-compose.terminology.yml`), Ollama runs **natively on the host** on port 11434, not in a container. On Apple Silicon this is the only way to use the Metal GPU. The bridge reaches Ollama via `host.docker.internal`. Models are loaded with `ollama pull <modell>`; alternatively, the older complete stack (`docker-compose.yml`) contains the container `ceir-ollama` with an init container that loads `qwen2.5:7b` automatically.

### Model Recommendations

Measured in November 2026 through the bridge with terminology questions (details on the [MCP Bridge](mcp-bridge-en.html) page):

| Model | Size | Tool calling | Time per question | Recommendation |
|--------|-------|--------------|-----------------|------------|
| `qwen2.5:7b` | 4.7 GB | reliable, does not translate abbreviations on its own | 10 to 20 s | WebUI **default** |
| `qwen3:14b` | 9.0 GB | best search terms, chains calls | 70 to 140 s | best quality, slow |
| `gpt-oss:20b` | 14 GB | good and fast calls | 20 to 35 s | candidate for the WebUI, needs a lot of RAM |
| `llama3.1:8b` | 4.7 GB | guesses codes and then looks them up | 10 to 20 s | unsuitable |

Large models push the native Open-Jev server into swap, and tool calls then run into the bridge's 120-second timeout. For this reason, the WebUI background tasks (titles, tags, search queries) are disabled in the Compose file and `TASK_MODEL` is set to `qwen2.5:7b`.

Loading models:

```bash
ollama pull qwen3:14b
```

### GPU Support

#### Apple Metal (macOS)

For optimal performance on macOS with Apple Silicon, Ollama should run **natively** on the host (not in a container):

1. Install Ollama natively: [ollama.com](https://ollama.com)
2. Set in the `.env`:

```env
OLLAMA_URL=http://host.docker.internal:11434
```

This is the **default** in CEIR-OS. The MCP Bridge accesses the native Ollama server via `host.docker.internal`.

#### NVIDIA GPU (Linux)

For NVIDIA GPUs, uncomment the GPU section in `docker-compose.yml`:

```yaml
ollama:
  # ...
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

Also set:

```env
OLLAMA_URL=http://ollama:11434
```

#### CPU Only

If no GPU is available, set:

```env
OLLAMA_URL=http://ollama:11434
```

Ollama then runs in CPU mode in the container. Inference is slower, but works.

### Open WebUI

| Property | Value |
|------------|------|
| Container | `ceir-webui` |
| Port | 3080 |
| Image | `ghcr.io/open-webui/open-webui:main` |

Open WebUI is the chat interface of CEIR-OS. It is configured so that all requests go through the MCP Bridge.

#### Important Settings

The following settings are already configured correctly in `docker-compose.terminology.yml`:

| Setting | Value | Explanation |
|------------|------|-----------|
| `ENABLE_OLLAMA_API` | `false` | Direct Ollama connection **disabled** |
| `ENABLE_OPENAI_API` | `true` | OpenAI API enabled (via bridge) |
| `OPENAI_API_BASE_URL` | `http://mcp-bridge:8000/v1` | Points to the MCP Bridge |
| `OPENAI_API_KEY` | `not-needed` | No real key needed |
| `WEBUI_AUTH` | `false` | No authentication (local) |
| `WEBUI_NAME` | `CEIR-OS` | Branding |

**Why disable Ollama?** If OpenWebUI communicates with Ollama directly, the MCP tools are bypassed. All requests must go through the MCP Bridge so that tool calls (terminology search, FHIR lookup, etc.) work.

#### Recommended Chat Settings in the OpenWebUI Interface

| Parameter | Value | Explanation |
|-----------|------|-----------|
| Temperature | 0.3 | Low for consistent terminology answers |
| num_ctx | 4096 | Context window (more = slower) |
| Top P | 0.9 | Nucleus sampling |

These settings can be adjusted per model in OpenWebUI under "Settings > Models".

### Typical Workflow

1. Open `http://localhost:3080` in the browser
2. Choose a model (e.g., `qwen2.5:7b`)
3. Ask a question such as: "What is the ICD-10 code for type 2 diabetes mellitus?"
4. The LLM recognizes the need for a tool, the bridge executes `search_codes` or `search_across_versions`, over several rounds if needed
5. The result (e.g., E11.9) is embedded in the answer; the 🔧 lines at the beginning show the calls
6. What reached the terminology server is recorded in `logs/terminology-mcp/terminology-calls.jsonl`

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `OLLAMA_PORT` | `11434` | Ollama host port |
| `WEBUI_PORT` | `3080` | OpenWebUI host port |
| `BRIDGE_PORT` | `8000` | MCP Bridge host port |
| `OLLAMA_URL` | `http://host.docker.internal:11434` | Ollama endpoint for the bridge |
