Diese Seite dokumentiert zentrale Architekturentscheidungen in CEIR-OS und deren Begründung. Sie dient dazu, das "Warum" hinter dem System zu bewahren, auch wenn die ursprünglichen Entscheider nicht verfügbar sind.

### ADR-1: Lokaler Snowstorm statt öffentlicher FHIR-Server

**Entscheidung:** CEIR-OS betreibt einen eigenen Snowstorm-Server statt tx.fhir.org oder andere öffentliche Terminologieserver zu nutzen.

**Begründung:**
- **Verfügbarkeit:** Öffentliche Server haben Rate Limits und sind nicht immer erreichbar. Für die Entwicklung und CI/CD-Pipelines brauchen wir zuverlässigen Zugang.
- **Performance:** Lokale Latenz (~10ms) vs. Netzwerk-Roundtrip (~200-500ms). Bei iterativer Arbeit mit vielen Abfragen macht das einen großen Unterschied.
- **Offline-Fähigkeit:** Arbeiten im Zug, im Flugzeug oder bei Netzwerkproblemen funktioniert weiterhin.
- **Kontrolle:** Wir bestimmen, welche SNOMED-Editionen geladen sind (International, DE, CH) und welche Version aktiv ist.

**Trade-off:** Höherer Ressourcenverbrauch (~4 GB RAM für Elasticsearch + Snowstorm), initialer Import dauert 10-30 Minuten.

### ADR-2: Eigener Terminology MCP statt direkter OntoServer-Zugriff

**Entscheidung:** Ein eigener MCP-Server aggregiert Snowstorm, lokale LOINC-Daten und den MII OntoServer hinter einer einheitlichen Schnittstelle.

**Begründung:**
- **Einheitliche API:** Claude Code und andere MCP-Clients sehen ein Tool (`lookup_code`) statt drei verschiedene Server mit unterschiedlichen Authentifizierungsmethoden.
- **mTLS-Abstraktion:** Der MII OntoServer erfordert mutual TLS. Der Terminology MCP übernimmt die Zertifikatsverwaltung, sodass Clients nichts davon wissen müssen.
- **Lokale Anreicherung:** LOINC-Daten (deutsche Labels, Panels, Answer Lists) kommen aus lokalen Dateien — schneller und umfangreicher als der OntoServer, der nur die LOINC-Haupttabelle hat.
- **Routing-Intelligenz:** Anhand der `system`-URL wird automatisch die richtige Quelle gewählt (SNOMED → Snowstorm, LOINC → lokal, ICD-10-GM → OntoServer).

**Trade-off:** Zusätzlicher Container, Routing-Logik muss gepflegt werden.

### ADR-3: Ollama nativ auf dem Host statt im Docker-Container

**Entscheidung:** Der Standard-Setup nutzt Ollama nativ auf dem Host (`host.docker.internal:11434`) statt im Docker-Container.

**Begründung:**
- **GPU-Zugriff:** Auf macOS (Apple Silicon) hat nur die native Ollama-Installation Zugriff auf Metal GPU-Beschleunigung. Docker auf macOS hat keinen GPU-Passthrough.
- **Performance:** Metal-beschleunigtes Inference ist 5-10x schneller als CPU-only im Container.
- **Flexibilität:** Ollama wird auch außerhalb von CEIR-OS genutzt (andere Projekte, direkte CLI-Nutzung). Ein gemeinsamer Server vermeidet doppelte Modell-Downloads.

**Alternative:** Für Linux-Systeme mit NVIDIA GPU kann Ollama im Container mit GPU-Passthrough laufen (`OLLAMA_URL=http://ollama:11434`). Die docker-compose.yml enthält die auskommentierte GPU-Konfiguration.

### ADR-4: MCP Bridge statt direkter Tool-Integration in OpenWebUI

**Entscheidung:** Eine eigene Bridge übersetzt MCP-Tools ins OpenAI Function Calling Format, statt die Tools direkt in OpenWebUI zu integrieren.

**Begründung:**
- **Entkopplung:** OpenWebUI kennt nur die OpenAI-API. Es muss nicht wissen, dass die Tools über MCP kommen. Wenn OpenWebUI durch eine andere UI ersetzt wird, bleibt die Bridge nutzbar.
- **Smart Features:** Die Bridge kann Retry-Strategien, Result Trimming und Tool Call Parsing implementieren, die für lokale LLMs nötig sind aber nicht in OpenWebUI gehören.
- **Multi-Client:** Dieselbe Bridge kann von OpenWebUI, eigenen Scripts oder anderen OpenAI-kompatiblen Clients genutzt werden.

**Trade-off:** Zusätzliche Netzwerk-Hops (UI → Bridge → Ollama + MCP-Server).

### ADR-5: Zwei Ports für den Terminology MCP (3000 + 3002)

**Entscheidung:** Der Terminology MCP Server exponiert zwei Ports: 3000 (HTTP REST) und 3002 (MCP SSE).

**Begründung:**
- **Port 3000 (HTTP REST):** Wird von der MCP Bridge und anderen Services genutzt, die klassische HTTP-Calls machen. Einfach zu debuggen mit curl.
- **Port 3002 (MCP SSE):** Server-Sent Events Endpunkt für das Model Context Protocol. Wird von Claude Code und anderen MCP-Clients genutzt.
- **Trennung:** Unterschiedliche Protokolle, unterschiedliche Clients, unterschiedliche Fehlerbilder. Zwei Ports machen Debugging einfacher als ein Multiplexer.

### ADR-6: SNOMED CT Editionen — International + DE + CH

**Entscheidung:** Es werden die Internationale Edition, die Deutsche Edition und die Schweizer Edition geladen.

**Begründung:**
- **International:** Basis für alle Abfragen, enthält die englischen Bezeichnungen und die vollständige Hierarchie.
- **Deutsche Edition (BfArM):** Enthält die offiziellen deutschen SNOMED CT Übersetzungen, relevant für die MII und deutsche FHIR-Profile.
- **Schweizer Edition:** Enthält französische und italienische Übersetzungen. Nützlich für mehrsprachige Projekte und die Zusammenarbeit mit Schweizer Partnern.

### ADR-7: Doctor Service als Compose Profile

**Entscheidung:** Der Doctor Health Check ist als Compose-Service mit `profiles: [doctor]` implementiert statt als separates Script.

**Begründung:**
- **Im Netzwerk:** Der Doctor läuft im Docker-Netzwerk und testet die echte Container-zu-Container-Konnektivität (DNS, HTTP, FHIR-Operationen). Das ist aussagekräftiger als Tests vom Host.
- **Keine Dependencies:** Braucht keine Installation auf dem Host (kein Python, kein jq). Nur Docker.
- **On-Demand:** Durch das Compose Profile startet der Doctor nicht bei `docker compose up`, sondern nur bei explizitem Aufruf (`docker compose run --rm doctor`).
- **Funktionale Tests:** Prüft nicht nur "ist der Port offen", sondern führt echte SNOMED-Lookups und LOINC-Abfragen durch den Proxy aus.
