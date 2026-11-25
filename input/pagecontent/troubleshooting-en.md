*Deutsche Fassung: [Fehlerbehebung](troubleshooting.html)*

This page describes common problems when running CEIR-OS and how to fix them. The sections on Elasticsearch, the unpacker and the importer apply to the older complete stack (`docker-compose.yml`); in the current stack (`docker-compose.terminology.yml`) the containers are called `snowstorm` and `terminology-mcp`.

### Containers can no longer reach HTTPS targets

**Symptom:** Searches via the OntoServer suddenly fail, `docker exec terminology-mcp wget -O /dev/null https://www.google.com/` aborts with "unexpected eof", while the machine itself is online. The error affects all containers.

**Cause:** Docker Desktop picks up the automatic proxy configuration (PAC) from macOS and routes container traffic through the corporate proxy, which cannot be resolved outside the corporate network. To check:

```bash
tail ~/Library/Containers/com.docker.docker/Data/log/host/httpproxy.log
# "routed via automatic system PAC file proxy http://proxy...:8080" = exactly this problem
```

**Fix:** In Docker Desktop, under Settings, Resources, Proxies, switch to manual configuration with no entries. Alternatively, restart Docker Desktop after a network or VPN change.

### "getaddrinfo ENOTFOUND blaze-full" in search responses

**Symptom:** `search_codes` or `/search` returns an OperationOutcome with `request to http://blaze-full:8080/fhir/ValueSet/$expand failed`.

**Cause:** The OntoServer was not reachable (certificate, network, server down) and the Blaze fallback is not running. The actual OntoServer error is not visible in this message.

**Diagnosis:**

```bash
curl -s localhost:3000/ready | jq .backends       # ontoserver: reachable?
docker exec terminology-mcp wget -q -O /dev/null --server-response https://ontoserver.mii-termserv.de/fhir/metadata 2>&1 | head -1   # 400 without a certificate is fine, a TLS error is not
```

**Fix:** Depending on the finding, check the network (see above), the certificate and the passphrase, or start Blaze as a fallback (`docker-compose.blaze-full.yml`).

### Startup aborts: "error while creating mount source path"

**Symptom:** `docker compose up` aborts for `terminology-mcp` with
`error while creating mount source path '/host_mnt/Users/<name>/...': mkdir ...: permission denied`.

**Cause:** The compose file points to a folder that does not exist on this machine; Docker tries to create it and is not allowed to. In older versions of ceir-os, the maintainer's certificate path was hard-coded in `docker-compose.terminology.yml`.

**Fix:** Update ceir-os (`git pull`). The paths now come from `.env`: `CERTS_PATH` for certificates (without an entry, an empty `./certs` is used and the stack starts without the OntoServer), `LOINC_PATH` for LOINC. Specify paths in `.env` as absolute paths; `~` is not expanded there. If the folder exists and the error persists, check in Docker Desktop under Settings, Resources, File sharing whether the folder is shared.

### Certificate is not decrypted ("bad decrypt")

**Symptom:** Right after startup, terminology-mcp reports "bad decrypt" and falls back to Blaze, even though the passphrase in `.env` is correct.

**Cause:** A `CERT_PASSPHRASE` variable exported in the shell (for example from `~/.zshrc`) overrides the value from `.env`.

**Fix:** `env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d --force-recreate terminology-mcp`, or remove the export.

### Docker Desktop does not start cleanly after a quit

**Symptom:** `docker info` only returns "dialing 192.168.65.x:2376: no route to host" or hangs; the Docker VM is gone, but the backend process is still running.

**Fix:** Terminate all `com.docker` processes and reopen Docker Desktop:

```bash
pkill -f 'Docker Desktop.app'; pkill -f com.docker.backend
open -a Docker
```

### Response lists codes without the search term

**Symptom:** The WebUI response to "Diabetes mellitus Typ" contains E14 or P70.2, even though "Typ" is missing from the display.

**Cause:** Bridge before November 2026: the retry logic could not read the MCP response and always returned the result for the shortest search term.

**Fix:** Rebuild the bridge (`docker compose -f docker-compose.terminology.yml build mcp-bridge`) and start it with `--force-recreate`. The call log then shows only the calls that are actually needed per question.

### Snowstorm does not start

**Symptom:** The `ceir-snowstorm` container restarts repeatedly or stays in the "starting" status.

**Cause 1: Elasticsearch does not have enough memory**

```bash
# Check Elasticsearch logs
docker logs ceir-elasticsearch 2>&1 | tail -20
```

Fix: Adjust `ES_JAVA_OPTS` in `.env`:

```env
ES_JAVA_OPTS="-Xms2g -Xmx2g"
```

Then restart:

```bash
docker compose down
docker compose up -d
```

**Cause 2: Elasticsearch is not healthy yet**

Snowstorm waits for the Elasticsearch health check. Check:

```bash
curl -s http://localhost:9200/_cluster/health | jq .status
```

The status must be `green` or `yellow`.

**Cause 3: SNOMED import failed**

```bash
docker logs ceir-snomed-importer
```

If the import was aborted, delete the marker file and restart:

```bash
docker compose down
docker volume rm ceir-os_sct_files
docker compose up -d
```

### Snowstorm DNS resolution failed

**Symptom:** The Terminology MCP Server cannot reach Snowstorm. `lookup_code` for SNOMED CT fails even though Snowstorm is running.

**Cause:** When Snowstorm is restarted on its own (e.g. `docker restart ceir-snowstorm`), the container loses its DNS alias in the Docker network. Other containers can then no longer resolve `snowstorm`.

**Diagnosis:**

```bash
# Run the doctor service — checks DNS and all routes
docker compose run --rm doctor
```

**Fix:** Recreate Snowstorm and dependent services via Docker Compose:

```bash
docker compose up -d --force-recreate snowstorm terminology-mcp
```

> **Important:** `docker restart` is not enough — it has to be `--force-recreate` so that Docker re-registers the DNS entries in the network.

### SNOMED import takes a very long time

Depending on the package size, the initial import can take 10-30 minutes. Check progress:

```bash
docker logs -f ceir-snomed-importer
```

During the import, Snowstorm is already started but not yet fully functional.

### MII OntoServer not reachable

**Symptom:** `search_codes` or `search_across_versions` return errors for ICD-10-GM, OPS or ATC, `curl -s localhost:3000/ready` shows `ontoserver: unreachable`.

**Cause 1: mTLS certificates are missing or invalid**

```bash
# Check Terminology MCP logs
docker logs terminology-mcp 2>&1 | grep -i cert
```

Check:
- Are the certificate files in the folder that `CERTS_PATH` in `.env` points to? The log then shows `Using volume-mounted certs in /app/certs-host`.
- Is `CERT_PASSPHRASE` set correctly?
- Are the Base64-encoded values (if used) complete?

**Cause 2: Network problems**

The MII OntoServer is an external service. Check reachability:

```bash
docker exec terminology-mcp wget -q -O /dev/null --server-response https://ontoserver.mii-termserv.de/fhir/metadata 2>&1 | head -1
```

HTTP 400 without a client certificate is the expected result; a TLS abort points to the proxy problem at the top of this page.

### Tools do not work in OpenWebUI

**Symptom:** The LLM answers without tool calls, codes are guessed.

**Cause 1: Ollama is connected directly (bridge bypassed)**

Check the OpenWebUI configuration:

```bash
docker inspect ceir-webui | jq '.[0].Config.Env' | grep -i ollama
```

`ENABLE_OLLAMA_API` must be `false`. If it is `true`, OpenWebUI communicates directly with Ollama and bypasses the MCP Bridge.

Fix: Make sure that `docker-compose.yml` contains:

```yaml
- ENABLE_OLLAMA_API=false
- ENABLE_OPENAI_API=true
- OPENAI_API_BASE_URL=http://mcp-bridge:8000/v1
```

**Cause 2: MCP Bridge has not discovered any tools**

```bash
curl -s http://localhost:8000/health | jq .
```

If `tools: 0`, the MCP servers are not reachable. Check the logs:

```bash
docker logs ceir-mcp-bridge 2>&1 | grep -i discover
```

**Cause 3: Model does not support tool calling**

Not all models support tool calling reliably. Recommended models:

| Model | Tool calling |
|--------|-------------|
| `qwen2.5:7b` | Good, fast |
| `qwen3:14b` | Very good, slow |
| `gpt-oss:20b` | Good, fast |
| `llama3.1:8b` | Unsuitable, guesses codes |

### LOINC search returns no German labels

**Symptom:** `search_common_loinc` or `get_german_label` return no German translations.

**Cause: LOINC data not mounted**

Check:

```bash
docker exec terminology-mcp ls /app/loinc/
```

The directory must contain the LOINC distribution. Check `LOINC_PATH` in `.env`:

```env
LOINC_PATH=/pfad/zu/Loinc_2.81
```

### Docker memory problems

**Symptom:** Containers are terminated with "OOMKilled".

Fix: Increase Docker resources (Docker Desktop > Settings > Resources):

| Resource | Minimum | Recommended |
|-----------|---------|-----------|
| RAM | 8 GB | 16 GB |
| Disk | 20 GB | 50 GB |
| CPUs | 2 | 4 |

Specifically for Elasticsearch:

```env
ES_JAVA_OPTS="-Xms1g -Xmx1g"
```

### Port conflicts

**Symptom:** Container does not start because of "port already in use".

Check which process is using the port:

```bash
lsof -i :8090  # Snowstorm
lsof -i :3000  # Terminology MCP
lsof -i :8000  # MCP Bridge
```

Fix: Change the port in `.env`:

```env
SNOWSTORM_PORT=9090
TERMINOLOGY_PROXY_PORT=3100
BRIDGE_PORT=8001
```

### Health checks for all services

CEIR-OS includes a built-in **doctor service** that checks all services, DNS resolution and functional routes:

```bash
docker compose run --rm doctor
```

The doctor runs 20 checks:

| Category | What is checked |
|-----------|-----------------|
| DNS resolution | All 5 service host names in the Docker network |
| Elasticsearch | Cluster health |
| Snowstorm (direct) | FHIR metadata, CodeSystems, concept lookup, FHIR CodeSystem lookup |
| SNOMED routing | Terminology proxy → Snowstorm (POST /lookup with real SNOMED codes) |
| LOINC local tools | German labels (Körpertemperatur, Kreatinin), panel index |
| Service health | Proxy HTTP, MCP SSE, Snowstorm connection, LOINC panels loaded |
| MCP Bridge | Health check |

Alternatively, there is the host-side script `./doctor.sh`, which additionally checks container status and cross-service connectivity from the outside.

For individual services:

```bash
# Snowstorm
curl -s http://localhost:8090/fhir/metadata | jq .software

# Terminology MCP
curl -s http://localhost:3002/health | jq .

# MCP Bridge
curl -s http://localhost:8000/health | jq .
```

### Full restart

If nothing else helps:

```bash
# Stop and remove all containers
docker compose -f docker-compose.terminology.yml down

# Start again
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d snowstorm terminology-mcp

# Follow the logs
docker compose -f docker-compose.terminology.yml logs -f
```

For the older complete setup (`docker-compose.yml`), the same commands apply without `-f`; there, `docker compose down -v` also deletes the SNOMED import.
