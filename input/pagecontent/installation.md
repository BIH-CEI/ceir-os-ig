Diese Seite beschreibt die Installation von CEIR-OS auf einem leeren Rechner: zuerst den Terminologie-Stack, dann das interaktive Mapping-Tool aus MCP Bridge und Open WebUI. Stand November 2026. Die Betriebsdetails (Routing, Versionen, Fallbacks) stehen im Repo unter `docs/terminology-routing.md`, die UI-Einstellungen unter `docs/openwebui-config.md`.

### Was läuft wo

Alle Dienste kommen aus einer Compose-Datei: `docker-compose.terminology.yml`. Sie nutzt fertige Images (Snowstorm mit SNOMED-Daten, terminology-mcp von GHCR oder lokal gebaut), ein eigener SNOMED-Import ist nicht mehr nötig. Jeder Dienst lässt sich einzeln starten, die Abhängigkeiten regelt Compose.

| Dienst | Container | Port (Host) | Aufgabe | Pflicht für |
|--------|-----------|-------------|---------|-------------|
| Snowstorm | `snowstorm` | 8090 (FHIR), 9200 (ES) | SNOMED CT lokal, Image enthält die Daten | alles |
| terminology-mcp | `terminology-mcp` | 3000 (REST-Proxy), 3002 (MCP SSE) | LOINC lokal, Routing zu Snowstorm, MII OntoServer (ICD-10-GM, OPS, ATC, LOINC, SNOMED), Blaze-Fallback | alles |
| decision-mcp | `ceir-decision-mcp` | 2027 | Open-Jev-Kandidaten-Ranking (`rank_candidates`) | Mapping-Tool, optional |
| mcp-bridge | `ceir-mcp-bridge` | 8000 | macht die MCP-Tools als OpenAI Function Calling für Ollama verfügbar | Mapping-Tool |
| Open WebUI | `ceir-webui` | 3080 | Chat-Oberfläche, spricht nur mit der Bridge | Mapping-Tool |
| SNOMED-Browser | `snomed-browser` | 8081 | Hierarchie anschauen | optional |

Außerhalb von Docker, nativ auf dem Rechner:

- **Ollama** auf Port 11434. Auf Apple Silicon geht Metal-Beschleunigung nur nativ, die Bridge erreicht Ollama über `host.docker.internal`.
- **Open-Jev-Modellserver** auf Port 8791, nur für decision-mcp. Ohne ihn laufen alle anderen Tools, `rank_candidates` meldet einen klaren Fehler.

Zwei Zugangspfade laufen parallel: Claude Desktop und Claude Code nutzen den MCP-SSE-Endpunkt (3002) direkt, Open WebUI geht über die Bridge auf den REST-Proxy (3000). Beide landen im selben Kern und im selben Call-Log.

### Voraussetzungen

| Komponente | Anforderung |
|------------|-------------|
| Rechner | Apple Silicon mit mindestens 32 GB RAM (Docker-VM 16 GB plus Ollama-Modelle mit 5 bis 14 GB); Linux mit NVIDIA-GPU geht ebenfalls |
| Docker Desktop | aktuelle Version, Compose v2, 16 GB Memory für die VM; **muss gestartet sein**, prüfen mit `docker info` (sonst `Cannot connect to the Docker daemon`) |
| Docker-Proxy | unter Settings, Resources, Proxies auf manuelle Konfiguration ohne Einträge stellen, falls macOS eine automatische Proxy-Konfiguration (PAC) hat, sonst leitet Docker allen Container-Verkehr über den Firmenproxy (siehe [Fehlerbehebung](troubleshooting.html)) |
| Ollama | nativ installiert und als Dienst gestartet, mindestens `qwen2.5:7b` gezogen |
| Werkzeuge | `git`, `jq`, `curl`; für den Benchmark zusätzlich `uv` |

Modelle laden:

```bash
brew install ollama
brew services start ollama  # Ollama als Hintergrunddienst starten (auch nach Neustart)
ollama pull qwen2.5:7b      # Standardmodell der WebUI, schnell
ollama pull qwen3:14b       # beste Tool-Qualität, langsam
ollama pull gpt-oss:20b     # schnell mit guten Tool-Aufrufen
ollama list
```

Checkliste Daten und Zugänge. Die Installation ist vorbereitet, wenn jede Pflichtzeile erledigt ist; alle Ordner sind frei wählbar.

| Erledigt? | Was | Woher | Wohin damit | Pflicht |
|-----------|-----|-------|-------------|---------|
| ☐ | LOINC-Distribution, entpackt (z. B. `Loinc_2.83/` mit `LoincTable/Loinc.csv`) | [loinc.org](https://loinc.org/downloads/), kostenlose Registrierung | beliebiger Ordner; dessen absoluten Pfad in Schritt 2 als `LOINC_PATH` in `.env` eintragen | ja |
| ☐ | Snowstorm-Image `snowstorm-complete:v1.2.0` | Tarball vom Team-Speicher oder Build aus dem Repo `local-snowstorm` | in Docker laden (Schritt 3, `docker load`) | ja |
| ☐ | terminology-mcp-Image | eine der drei Varianten in Schritt 3 | in Docker laden bzw. bauen (Schritt 3) | ja |
| ☐ | mTLS-Zertifikat für den MII-Terminologieserver (`<Name>.pem`, `<Name>.key`, `rootca.pem`, `intermediate.pem`) plus Passphrase | teamintern, Zertifikat auf das Team ausgestellt | beliebiger Ordner, am besten außerhalb des Repos; Pfad als `CERTS_PATH`, Passphrase als `CERT_PASSPHRASE` in `.env`. Entfällt mit dem internen Image (Schritt 3, Variante B) | nein |

Ohne Zertifikat läuft der Stack trotzdem: SNOMED über Snowstorm, LOINC über den lokalen Index. Alles andere meldet den OntoServer als nicht erreichbar.

### Schritt 1: Repos holen

Der Ablageort ist frei wählbar. Die Beispiele unten gehen davon aus, dass du im Ordner arbeitest, der `ceir-os` enthält.

```bash
cd <dein-arbeitsordner>
git clone https://github.com/BIH-CEI/ceir-os.git
git clone https://github.com/BIH-CEI/agentic-terminology-mapping.git   # Benchmark, optional; erwartet ceir-os daneben
```

Das Repo `terminology-proxy-mcp` brauchst du nur für Variante C in Schritt 3 (Image selbst bauen). Zertifikate müssen nicht darin liegen.

### Schritt 2: Konfigurieren

```bash
cd ceir-os
cp .env.example .env
```

In `.env` mindestens setzen:

| Variable | Beispiel | Beschreibung |
|----------|----------|--------------|
| `LOINC_PATH` | `/Users/me/terminologies/Loinc_2.83` | entpackte LOINC-Distribution (absoluter Pfad) |
| `TERMINOLOGY_MCP_VERSION` | `latest` oder ein Release-Tag | Image-Tag von terminology-mcp (Variante aus Schritt 3) |
| `SNOWSTORM_IMAGE_TAG` | `v1.2.0` | lokales Snowstorm-Image |
| `CERTS_PATH` | `/Users/me/secrets/mii-certs` | nur mit Zertifikat: Ordner mit den Zertifikatsdateien |
| `CERT_PASSPHRASE` | teamintern | nur mit Zertifikat |

Pfade in `.env` absolut angeben, `~` wird dort nicht aufgelöst. Bei genau einem `<Name>.pem` plus `<Name>.key` im Zertifikatsordner erkennt der Container das Paar selbst, sonst `CERT_CLIENT_NAME` setzen. `TERMINOLOGY_PROXY_PATH` in `.env.example` gehört zum älteren `docker-compose.yml` und kann für den aktuellen Stack ignoriert werden.

> **Wichtig:** Variablen aus der Shell schlagen `.env`. Steht in `~/.zshrc` ein altes `export CERT_PASSPHRASE=...`, nimmt Compose dieses und der Container fällt mit "bad decrypt" auf Blaze zurück. Abhilfe beim Start: `env -u CERT_PASSPHRASE docker compose ...`.

### Schritt 3: Images bereitstellen

**Snowstorm** aus dem Tarball laden:

```bash
docker load -i snowstorm-complete-v1.2.0.tar
docker images snowstorm-complete
```

**terminology-mcp: genau eine der drei Varianten wählen.**

| Variante | Für wen | Zertifikat | Zugang |
|----------|---------|------------|--------|
| A: Standard-Image aus GHCR | alle mit Zugriff auf die BIH-CEI-Packages | separat über `CERTS_PATH`, oder ohne | GitHub-Token |
| B: internes Image mit eingebautem Zertifikat | Teammitglieder | ist im Image | GitHub-Token |
| C: Image selbst bauen | ohne GHCR-Zugang | separat über `CERTS_PATH`, oder ohne | keiner |

GHCR ist die GitHub Container Registry, der Image-Speicher von GitHub. Die Images von BIH-CEI sind privat, für A und B brauchst du deshalb einen Token: auf GitHub unter Settings, Developer settings, Personal access tokens (classic) einen Token mit dem Recht `read:packages` anlegen und, falls angeboten, über "Configure SSO" für die Organisation BIH-CEI freischalten. Ausführlich: [docs/ghcr-setup.md](https://github.com/BIH-CEI/ceir-os/blob/main/docs/ghcr-setup.md).

```bash
echo <TOKEN> | docker login ghcr.io -u <github-benutzername> --password-stdin
```

Variante A:

```bash
docker compose -f docker-compose.terminology.yml pull terminology-mcp
```

Variante B: in `.env` das interne Image eintragen, dann ziehen. `CERTS_PATH` bleibt leer; die Passphrase (`CERT_PASSPHRASE`) ist weiterhin nötig.

```bash
TERMINOLOGY_MCP_IMAGE=ghcr.io/bih-cei/terminology-mcp/terminology-mcp-internal
TERMINOLOGY_MCP_VERSION=v1.1.3
TERMINOLOGY_MCP_CERT_DIR=/app/certs
```

```bash
docker compose -f docker-compose.terminology.yml pull terminology-mcp
```

Variante C lokal bauen, ohne GHCR-Zugang. Die Build-Stufe für LOINC-Daten wird durch ein leeres Verzeichnis ersetzt, weil die Compose LOINC ohnehin mountet:

```bash
git clone https://github.com/BIH-CEI/terminology-proxy-mcp.git
cd terminology-proxy-mcp
mkdir -p /tmp/loinc-ctx/loinc
docker buildx build -f docker/Terminology-MCP.Dockerfile \
  -t ghcr.io/bih-cei/terminology-mcp/terminology-mcp:local \
  --build-context loinc-data=/tmp/loinc-ctx --load .
```

Dann in `.env` `TERMINOLOGY_MCP_VERSION=local` eintragen. Bridge und decision-mcp baut Compose beim ersten Start selbst aus `src/mcp_bridge` und `src/decision_mcp`.

### Schritt 4: Terminologie-Stack starten

Snowstorm braucht beim Kaltstart bis zu fünf Minuten.

```bash
cd ceir-os
docker info > /dev/null && echo "Docker läuft"   # sonst Docker Desktop starten
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d snowstorm terminology-mcp
docker compose -f docker-compose.terminology.yml ps
curl -s localhost:3000/health | jq .            # Proxy lebt, zeigt Version
curl -s localhost:3000/ready  | jq .backends    # ontoserver / snowstorm / blaze erreichbar?
./doctor.sh                                     # Gesamtcheck aller Dienste
```

Funktionsprobe über den REST-Proxy. Die Quelle muss `OntoServer` (mit Zertifikat) oder `Snowstorm` sein:

```bash
curl -s localhost:3000/search -H 'Content-Type: application/json' \
  -d '{"system":"http://loinc.org","filter":"interventricular septum diastole","count":5}' \
  | jq '{source:._source, total:.expansion.total, codes:[.expansion.contains[]|.code]}'
```

### Schritt 5: Mapping-Tool starten

```bash
env -u CERT_PASSPHRASE docker compose -f docker-compose.terminology.yml up -d mcp-bridge open-webui
curl -s localhost:8000/health                       # {"status":"ok","tools":20}: Tools von :3000/tools entdeckt
curl -s localhost:8000/v1/models | jq '.data[].id'  # Ollama-Modelle sichtbar
open http://localhost:3080
```

Open WebUI läuft ohne Login (`WEBUI_AUTH=false`), Standardmodell ist `qwen2.5:7b`. Modell oben links wechseln, dann eine Frage stellen, zum Beispiel:

> Welcher LOINC-Code passt zu der Echo-Variable IVSd (interventricular septum thickness in diastole)? Nutze die Terminologie-Tools und nenne Code und Display.

Die Antwort beginnt mit den ausgeführten Tool-Aufrufen (🔧-Zeilen). Was wirklich beim Terminologieserver ankam, steht im Call-Log, das die Compose nach `logs/terminology-mcp/` mountet:

```bash
jq -c 'select(.transport=="rest") | {ts:.timestamp, tool, args, source, result_count}' \
  logs/terminology-mcp/terminology-calls.jsonl | tail -20
```

**Open-Jev** für decision-mcp: den Modellserver nativ starten, sodass er unter `http://localhost:8791/v1/systemone` antwortet (eigenes Repo). `curl localhost:2027/health` meldet beide Backends.

### Schritt 6: Benchmark (optional)

Die agentischen Evals mit Inspect AI laufen headless gegen denselben Stack:

```bash
cd ../agentic-terminology-mapping   # liegt neben ceir-os
make setup          # uv sync
make stack-up       # startet den Stack aus ../ceir-os
make stack-status
make eval-loinc MODEL=qwen3:14b
```

### Stoppen, aktualisieren, zurückrollen

```bash
docker compose -f docker-compose.terminology.yml stop open-webui mcp-bridge   # nur das Mapping-Tool
docker compose -f docker-compose.terminology.yml down                         # alles, Volumes bleiben
docker compose -f docker-compose.terminology.yml build mcp-bridge && \
docker compose -f docker-compose.terminology.yml up -d --force-recreate mcp-bridge   # Bridge-Code geändert
```

Neue terminology-mcp-Version: Tag in `.env` ändern, dann `up -d terminology-mcp`. Zurück zur alten Version: alten Tag eintragen, alte Images bleiben lokal liegen.

### Weitere Compose-Dateien

| Datei | Inhalt |
|-------|--------|
| `docker-compose.yml` | älterer Komplettaufbau mit eigenem SNOMED-Import aus `SNOMED_PACKAGE_PATH`, Ollama im Container und Doctor-Service; nur nötig, wenn kein fertiges Snowstorm-Image verfügbar ist |
| `docker-compose.blaze-full.yml` | Blaze als Fallback für den OntoServer (etwa 10 GB Heap, Kaltstart sechs Minuten) |
| `docker-compose.blaze-tx.yml` | lokaler MII-Tx-Server als Offline-Fallback |
| `docker-compose.snomed-mcp.yml` | SNOMED-MCP für ECL, Hierarchie und Konzeptdetails gegen Snowstorm |
