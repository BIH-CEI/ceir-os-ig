*Deutsche Fassung: [Architekturentscheidungen](architekturentscheidungen.html)*

This page documents the central architecture decisions in CEIR-OS and their rationale. It serves to preserve the "why" behind the system, even when the original decision makers are not available.

### ADR-1: Local Snowstorm instead of public FHIR servers

**Decision:** CEIR-OS runs its own Snowstorm server instead of using tx.fhir.org or other public terminology servers.

**Rationale:**
- **Availability:** Public servers have rate limits and are not always reachable. For development and CI/CD pipelines we need reliable access.
- **Performance:** Local latency (~10ms) vs. network round trip (~200-500ms). In iterative work with many queries this makes a big difference.
- **Offline capability:** Working on the train, on the plane or during network problems still works.
- **Control:** We decide which SNOMED editions are loaded (International, DE, CH) and which version is active.

**Trade-off:** Higher resource consumption (~4 GB RAM for Elasticsearch + Snowstorm); the initial import takes 10-30 minutes.

### ADR-2: Own Terminology MCP instead of direct OntoServer access

**Decision:** A dedicated MCP server aggregates Snowstorm, local LOINC data and the MII terminology server (OntoServer) behind a uniform interface.

**Rationale:**
- **Uniform API:** Claude Code and other MCP clients see one tool (`lookup_code`) instead of three different servers with different authentication methods.
- **mTLS abstraction:** The MII terminology server (OntoServer) requires mutual TLS. The Terminology MCP takes care of certificate management, so clients do not need to know anything about it.
- **Local enrichment:** LOINC data (German labels, panels, answer lists) comes from local files: faster and more comprehensive than the OntoServer, which only has the main LOINC table.
- **Routing intelligence:** Based on the `system` URL, the right source is selected automatically (SNOMED → Snowstorm, LOINC → local, ICD-10-GM → OntoServer).

**Trade-off:** Additional container; the routing logic has to be maintained.

### ADR-3: Ollama natively on the host instead of in a Docker container

**Decision:** The default setup uses Ollama natively on the host (`host.docker.internal:11434`) instead of in a Docker container.

**Rationale:**
- **GPU access:** On macOS (Apple Silicon), only the native Ollama installation has access to Metal GPU acceleration. Docker on macOS has no GPU passthrough.
- **Performance:** Metal-accelerated inference is 5-10x faster than CPU-only in the container.
- **Flexibility:** Ollama is also used outside of CEIR-OS (other projects, direct CLI use). A shared server avoids duplicate model downloads.

**Alternative:** On Linux systems with an NVIDIA GPU, Ollama can run in the container with GPU passthrough (`OLLAMA_URL=http://ollama:11434`). The docker-compose.yml contains the commented-out GPU configuration.

### ADR-4: MCP Bridge instead of direct tool integration in OpenWebUI

**Decision:** A dedicated bridge translates MCP tools into the OpenAI function calling format instead of integrating the tools directly into OpenWebUI.

**Rationale:**
- **Decoupling:** OpenWebUI only knows the OpenAI API. It does not need to know that the tools come via MCP. If OpenWebUI is replaced by another UI, the bridge remains usable.
- **Smart features:** The bridge can implement retry strategies, result trimming and tool call parsing, which are needed for local LLMs but do not belong in OpenWebUI.
- **Multi-client:** The same bridge can be used by OpenWebUI, custom scripts or other OpenAI-compatible clients.

**Trade-off:** Additional network hops (UI → Bridge → Ollama + MCP server).

### ADR-5: Two ports for the Terminology MCP (3000 + 3002)

**Decision:** The Terminology MCP server exposes two ports: 3000 (HTTP REST) and 3002 (MCP SSE).

**Rationale:**
- **Port 3000 (HTTP REST):** Used by the MCP Bridge and other services that make classic HTTP calls. Easy to debug with curl.
- **Port 3002 (MCP SSE):** Server-Sent Events endpoint for the Model Context Protocol. Used by Claude Code and other MCP clients.
- **Separation:** Different protocols, different clients, different failure patterns. Two ports make debugging easier than a multiplexer.

### ADR-6: SNOMED CT editions: International + DE + CH

**Decision:** The International Edition, the German Edition and the Swiss Edition are loaded.

**Rationale:**
- **International:** Basis for all queries; contains the English terms and the complete hierarchy.
- **German Edition (BfArM):** Contains the official German SNOMED CT translations, relevant for the MII and German FHIR profiles.
- **Swiss Edition:** Contains French and Italian translations. Useful for multilingual projects and collaboration with Swiss partners.

### ADR-7: Doctor service as a Compose profile

**Decision:** The Doctor health check is implemented as a Compose service with `profiles: [doctor]` instead of as a separate script.

**Rationale:**
- **Inside the network:** The Doctor runs in the Docker network and tests the real container-to-container connectivity (DNS, HTTP, FHIR operations). This is more meaningful than tests from the host.
- **No dependencies:** Needs no installation on the host (no Python, no jq). Only Docker.
- **On demand:** Thanks to the Compose profile, the Doctor does not start with `docker compose up`, but only when called explicitly (`docker compose run --rm doctor`).
- **Functional tests:** Checks not only "is the port open", but runs real SNOMED lookups and LOINC queries through the proxy.
