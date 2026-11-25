*Deutsche Fassung: [Installation](installation.html)*

This page describes how to install CEIR-OS on a clean machine: first the terminology stack, then the interactive mapping tool made up of MCP Bridge and Open WebUI. As of November 2026. The operational details (routing, versions, fallbacks) are in the repo under `docs/terminology-routing.md`, the UI settings under `docs/openwebui-config.md`.

### What runs where

All services come from a single Compose file: `docker-compose.terminology.yml`. It uses prebuilt images (Snowstorm with SNOMED data, terminology-mcp from GHCR or built locally); a separate SNOMED import is no longer needed. Each service can be started on its own; Compose handles the dependencies.

| Service | Container | Port (host) | Purpose | Required for |
|--------|-----------|-------------|---------|-------------|
| Snowstorm | `snowstorm` | 8090 (FHIR), 9200 (ES) | SNOMED CT locally, the image contains the data | everything |
| terminology-mcp | `terminology-mcp` | 3000 (REST proxy), 3002 (MCP SSE) | LOINC locally, routing to Snowstorm, MII OntoServer (ICD-10-GM, OPS, ATC, LOINC, SNOMED), Blaze fallback | everything |
| decision-mcp | `ceir-decision-mcp` | 2027 | Open-Jev candidate ranking (`rank_candidates`) | mapping tool, optional |
| mcp-bridge | `ceir-mcp-bridge` | 8000 | makes the MCP tools available to Ollama as OpenAI function calling | mapping tool |
| Open WebUI | `ceir-webui` | 3080 | chat interface, talks only to the bridge | mapping tool |
| SNOMED browser | `snomed-browser` | 8081 | browse the hierarchy | optional |

Outside of Docker, running natively on the machine:

- **Ollama** on port 11434. On Apple Silicon, Metal acceleration only works natively; the bridge reaches Ollama via `host.docker.internal`.
- **Open-Jev model server** on port 8791, only for decision-mcp. Without it all other tools still work; `rank_candidates` reports a clear error.

Two access paths run in parallel: Claude Desktop and Claude Code use the MCP SSE endpoint (3002) directly, Open WebUI goes through the bridge to the REST proxy (3000). Both end up in the same core and in the same call log.

### Prerequisites

| Component | Requirement |
|------------|-------------|
| Machine | Apple Silicon with at least 32 GB RAM (Docker VM 16 GB plus Ollama models of 5 to 14 GB); Linux with an NVIDIA GPU works as well |
| Docker Desktop | current version, Compose v2, 16 GB memory for the VM; **must be running**, check with `docker info` (otherwise `Cannot connect to the Docker daemon`) |
| Docker proxy | under Settings, Resources, Proxies, switch to manual configuration with no entries if macOS has an automatic proxy configuration (PAC); otherwise Docker routes all container traffic through the corporate proxy (see [Troubleshooting](troubleshooting-en.html)) |
| Ollama | installed natively and started as a service, with at least `qwen2.5:7b` pulled |
| Tools | `git`, `jq`, `curl`; additionally `uv` for the benchmark |

Load the models:

```bash
brew install ollama
brew services start ollama  # start Ollama as a background service (also after reboot)
ollama pull qwen2.5:7b      # default model of the WebUI, fast
ollama pull qwen3:14b       # best tool quality, slow
ollama pull gpt-oss:20b     # fast with good tool calls
ollama list
```

Checklist of data and access. The installation is prepared once every required row is done; all folders can be chosen freely.

| Done? | What | Where from | Where to put it | Required |
|-----------|-----|-------|-------------|---------|
| ☐ | LOINC distribution, unpacked (e.g. `Loinc_2.83/` with `LoincTable/Loinc.csv`) | [loinc.org](https://loinc.org/downloads/), free registration | any folder; enter its absolute path as `LOINC_PATH` in `.env` in step 2 | yes |
| ☐ | Snowstorm image `snowstorm-complete:v1.2.0` | tarball from the team storage or build from the repo `local-snowstorm` | load into Docker (step 3, `docker load`) | yes |
| ☐ | terminology-mcp image | one of the three variants in step 3 | load into Docker or build (step 3) | yes |
| ☐ | mTLS certificate for the MII OntoServer (`<Name>.pem`, `<Name>.key`, `rootca.pem`, `intermediate.pem`) plus passphrase | team-internal, certificate issued to the team | any folder, preferably outside the repo; path as `CERTS_PATH`, passphrase as `CERT_PASSPHRASE` in `.env`. Not needed with the internal image (step 3, variant B) | no |

The stack runs even without a certificate: SNOMED via Snowstorm, LOINC via the local index. Everything else reports the OntoServer as unreachable.

### Step 1: Get the repos

The location is up to you. The examples below assume that you are working in the folder that contains `ceir-os`.

```bash
cd <dein-arbeitsordner>
git clone https://github.com/BIH-CEI/ceir-os.git
git clone https://github.com/BIH-CEI/agentic-terminology-mapping.git   # benchmark, optional; expects ceir-os next to it
```

You only need the repo `terminology-proxy-mcp` for variant C in step 3 (build the image yourself). Certificates do not have to be stored in it.

### Step 2: Configure

```bash
cd ceir-os
cp .env.example .env
```

Set at least the following in `.env`:

| Variable | Example | Description |
|----------|----------|--------------|
| `LOINC_PATH` | `/Users/me/terminologies/Loinc_2.83` | unpacked LOINC distribution (absolute path) |
| `TERMINOLOGY_MCP_VERSION` | `latest` or a release tag | image tag of terminology-mcp (variant from step 3) |
| `SNOWSTORM_IMAGE_TAG` | `v1.2.0` | local Snowstorm image |
| `CERTS_PATH` | `/Users/me/secrets/mii-certs` | only with a certificate: folder containing the certificate files |
| `CERT_PASSPHRASE` | team-internal | only with a certificate |

Give absolute paths in `.env`; `~` is not expanded there. If there is exactly one `<Name>.pem` plus `<Name>.key` in the certificate folder, the container detects the pair by itself; otherwise set `CERT_CLIENT_NAME`. `TERMINOLOGY_PROXY_PATH` in `.env.example` belongs to the older `docker-compose.yml` and can be ignored for the current stack.

> **Important:** Variables from the shell take precedence over `.env`. If `~/.zshrc` contains an old `export CERT_PASSPHRASE=...`, Compose uses it and the container falls back to Blaze with "bad decrypt". Workaround at startup: `env -u CERT_PASSPHRASE docker compose ...`.

### Step 3: Provide the images

Load **Snowstorm** from the tarball:

```bash
docker load -i snowstorm-complete-v1.2.0.tar
docker images snowstorm-complete
```

**terminology-mcp: choose exactly one of the three variants.**

| Variant | For whom | Certificate | Access |
|----------|---------|------------|--------|
| A: standard image from GHCR | everyone with access to the BIH-CEI packages | separately via `CERTS_PATH`, or none | GitHub token |
| B: internal image with built-in certificate | team members | is in the image | GitHub token |
| C: build the image yourself | without GHCR access | separately via `CERTS_PATH`, or none | none |

GHCR is the GitHub Container Registry, GitHub's image storage. The BIH-CEI images are private, so for A and B you need a token: on GitHub under Settings, Developer settings, Personal access tokens (classic), create a token with the `read:packages` scope and, if offered, authorize it for the BIH-CEI organization via "Configure SSO". Details: [docs/ghcr-setup.md](https://github.com/BIH-CEI/ceir-os/blob/main/docs/ghcr-setup.md).

```bash
echo <TOKEN> | docker login ghcr.io -u <github-benutzername> --password-stdin
```

Variant A:

```bash
docker compose -f docker-compose.terminology.yml pull terminology-mcp
```

Variant B: enter the internal image in `.env`, then pull. `CERTS_PATH` stays empty; the passphrase (`CERT_PASSPHRASE`) is still required.

```bash
TERMINOLOGY_MCP_IMAGE=ghcr.io/bih-cei/terminology-mcp/terminology-mcp-internal
TERMINOLOGY_MCP_VERSION=v1.1.3
TERMINOLOGY_MCP_CERT_DIR=/app/certs
```

```bash
docker compose -f docker-compose.terminology.yml pull terminology-mcp
```

Variant C: build locally, without GHCR access. The build stage for LOINC data is replaced by an empty directory, because the Compose mounts LOINC anyway:

```bash
git clone https://github.com/BIH-CEI/terminology-proxy-mcp.git
cd terminology-proxy-mcp
mkdir -p /tmp/loinc-ctx/loinc
docker buildx build -f docker/Terminology-MCP.Dockerfile \
  -t ghcr.io/bih-cei/terminology-mcp/terminology-mcp:local \
  --build-context loinc-data=/tmp/loinc-ctx --load .
```

Then enter `TERMINOLOGY_MCP_VERSION=local` in `.env`. Compose builds the bridge and decision-mcp by itself from `src/mcp_bridge` and `src/decision_mcp` on first start.

### Step 4: Start the terminology stack

Snowstorm needs up to five minutes on a cold start.

```bash
cd ceir-os
docker info > /dev/null && echo "Docker läuft"   # otherwise start Docker Desktop
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d snowstorm terminology-mcp
docker compose -f docker-compose.terminology.yml ps
curl -s localhost:3000/health | jq .            # proxy alive, shows version
curl -s localhost:3000/ready  | jq .backends    # ontoserver / snowstorm / blaze reachable?
./doctor.sh                                     # overall check of all services
```

Smoke test via the REST proxy. The source must be `OntoServer` (with certificate) or `Snowstorm`:

```bash
curl -s localhost:3000/search -H 'Content-Type: application/json' \
  -d '{"system":"http://loinc.org","filter":"interventricular septum diastole","count":5}' \
  | jq '{source:._source, total:.expansion.total, codes:[.expansion.contains[]|.code]}'
```

### Step 5: Start the mapping tool

```bash
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d mcp-bridge open-webui
curl -s localhost:8000/health                       # {"status":"ok","tools":20}: tools discovered from :3000/tools
curl -s localhost:8000/v1/models | jq '.data[].id'  # Ollama models visible
open http://localhost:3080
```

Open WebUI runs without login (`WEBUI_AUTH=false`); the default model is `qwen2.5:7b`. Switch the model at the top left, then ask a question, for example:

> Which LOINC code matches the echo variable IVSd (interventricular septum thickness in diastole)? Use the terminology tools and give the code and display.

The answer starts with the executed tool calls (🔧 lines). What actually reached the terminology server is recorded in the call log, which the Compose mounts to `logs/terminology-mcp/`:

```bash
jq -c 'select(.transport=="rest") | {ts:.timestamp, tool, args, source, result_count}' \
  logs/terminology-mcp/terminology-calls.jsonl | tail -20
```

**Open-Jev** for decision-mcp: start the model server natively so that it responds at `http://localhost:8791/v1/systemone` (separate repo). `curl localhost:2027/health` reports both backends.

### Step 6: Benchmark (optional)

The agentic evals with Inspect AI run headless against the same stack:

```bash
cd ../agentic-terminology-mapping   # located next to ceir-os
make setup          # uv sync
make stack-up       # starts the stack from ../ceir-os
make stack-status
make eval-loinc MODEL=qwen3:14b
```

### Stop, update, roll back

```bash
docker compose -f docker-compose.terminology.yml stop open-webui mcp-bridge   # only the mapping tool
docker compose -f docker-compose.terminology.yml down                         # everything, volumes are kept
docker compose -f docker-compose.terminology.yml build mcp-bridge && \
docker compose -f docker-compose.terminology.yml up -d --force-recreate mcp-bridge   # bridge code changed
```

New terminology-mcp version: change the tag in `.env`, then `up -d terminology-mcp`. Back to the old version: enter the old tag; old images remain available locally.

### Further Compose files

| File | Contents |
|-------|--------|
| `docker-compose.yml` | older complete setup with its own SNOMED import from `SNOMED_PACKAGE_PATH`, Ollama in a container and doctor service; only needed if no prebuilt Snowstorm image is available |
| `docker-compose.blaze-full.yml` | Blaze as a fallback for the OntoServer (about 10 GB heap, six-minute cold start) |
| `docker-compose.blaze-tx.yml` | local MII Tx server as an offline fallback |
| `docker-compose.snomed-mcp.yml` | SNOMED MCP for ECL, hierarchy and concept details against Snowstorm |
