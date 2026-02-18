Der Terminology MCP Server ist der zentrale Terminologie-Zugang in CEIR-OS. Er bündelt den Zugriff auf mehrere Terminologie-Quellen in einer einheitlichen Schnittstelle.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-terminology-mcp` |
| Port 3000 | HTTP REST Proxy |
| Port 3002 | MCP SSE Endpunkt |
| Image | Eigener Build aus `terminology-proxy-mcp/` |

Der Server stellt **zwei Schnittstellen** bereit:

- **Port 3000 (HTTP REST)**: Klassische HTTP-Endpunkte für Terminologie-Abfragen. Wird von der MCP Bridge und anderen Services genutzt.
- **Port 3002 (MCP SSE)**: Server-Sent Events Endpunkt für das Model Context Protocol. Wird von Claude Code und anderen MCP-Clients genutzt.

### Unterstützte CodeSysteme nach Quelle

Der Terminology MCP Server bündelt drei verschiedene Terminologie-Quellen in einer einheitlichen Schnittstelle. Die Quelle bestimmt Verfügbarkeit, Latenz und Konfigurationsaufwand.

#### Lokal: Snowstorm (eigener FHIR TermServer)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| SNOMED CT | `http://snomed.info/sct` | FHIR R4 API via Snowstorm (Elasticsearch) |

- **Betrieb**: Eigener Container (`ceir-snowstorm`), benötigt Elasticsearch und SNOMED-RF2-Import
- **Bezug**: SNOMED CT ZIP-Datei intern via BIH SharePoint (wird direkt als Volume gemountet)
- **Latenz**: Niedrig (lokales Netzwerk)
- **Offline-fähig**: Ja

#### Lokal: Dateibasiert (vorindexiert)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| LOINC | `http://loinc.org` | Lokale JSON-Indizes + LOINC-Linguistik-Dateien |

- **Betrieb**: Dateien werden beim Containerstart aus `LOINC_PATH` geladen
- **Lizenz**: [Regenstrief LOINC License](https://loinc.org/license/) (kostenlos nach Registrierung)
- **Besonderheit**: Deutsche Labels, Panels, Answer Lists — kein externer Server nötig
- **Latenz**: Sehr niedrig (In-Memory)
- **Offline-fähig**: Ja

#### Remote: MII OntoServer (mTLS-gesichert)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` | FHIR R4 API via MII Terminologieserver |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` | FHIR R4 API via MII Terminologieserver |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` | FHIR R4 API via MII Terminologieserver |

- **Betrieb**: Externer Server der Medizininformatik-Initiative, Zugang über mutual TLS (mTLS)
- **Lizenz**: BfArM-Terminologien, Zugang über MII-Mitgliedschaft
- **Besonderheit**: Versionsübergreifende Suche (z.B. ICD-10-GM 2009–2025)
- **Latenz**: Mittel (Netzwerk-Roundtrip)
- **Offline-fähig**: Nein — erfordert Netzwerkverbindung und gültige Zertifikate

### Routing-Logik

Der Terminology MCP Server routet Anfragen automatisch an die richtige Quelle:

```
Anfrage ──► system URL erkennen
            ├── snomed.info/sct     ──► Snowstorm (lokal, Port 8080)
            ├── loinc.org           ──► Lokale Dateien (In-Memory)
            └── fhir.de/CodeSystem/ ──► MII OntoServer (mTLS, remote)
```

### MII OntoServer Anbindung

Der Zugriff auf den MII OntoServer erfolgt über mutual TLS (mTLS). Dafür werden folgende Zertifikate benötigt:

Zertifikate werden **zur Laufzeit** bereitgestellt — nie im Image:

| Zertifikat | Lokal (Volume-Mount) | CI/CD (Env-Var) |
|-----------|---------------------|-----------------|
| Client-Zertifikat | `certs/client.pem` | `CERT_CLIENT_PEM_B64` |
| Privater Schlüssel | `certs/client.key` | `CERT_CLIENT_KEY_B64` |
| Root CA | `certs/root-ca.pem` | `CERT_ROOT_CA_B64` |
| Intermediate CA | `certs/intermediate.pem` | `CERT_INTERMEDIATE_B64` |

Die `CERT_PASSPHRASE` ist bei Thomas Debertshäuser zu erfragen (in beiden Varianten als Umgebungsvariable).

### Lokale LOINC-Daten

Die lokale LOINC-Suche bietet gegenüber Server-Abfragen mehrere Vorteile:

- **Deutsche Labels**: Übersetzungen aus der offiziellen LOINC-Linguistik-Datei
- **Schnelle Suche**: Vorindexierte Daten, kein Netzwerk-Roundtrip
- **Panels**: Hierarchische Gruppierung von LOINC-Codes
- **Answer Lists**: Zuordnung von LOINC Answer Codes

Die Daten werden beim Containerstart aus dem gemounteten `LOINC_PATH`-Verzeichnis geladen.

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `SNOWSTORM_URL` | `http://snowstorm:8080/fhir` | Snowstorm FHIR-Endpunkt |
| `CERT_PASSPHRASE` | - | Bei Thomas Debertshäuser erfragen |
| `CERT_DIR` | `/app/certs` | Verzeichnis für Zertifikat-Dateien |
| `LOINC_DIR` | `/app/loinc` | Verzeichnis für LOINC-Daten |
| `PORT` | `3000` | HTTP REST Proxy Port |
| `MCP_PORT` | `3002` | MCP SSE Port |
| `HOST` | `0.0.0.0` | Bind-Adresse |

### Health Check

```bash
# HTTP Proxy
curl -s http://localhost:3000/health

# MCP SSE
curl -s http://localhost:3002/health
```

Beide Endpunkte müssen healthy sein, damit der Container als gesund gilt.

### Verfügbare Tools

Der Terminology MCP Server stellt 8 Tools bereit. Eine detaillierte Beschreibung aller Tools mit Parametern und Beispielen findest du auf der Seite [Terminologie-Tools](terminologie-tools.html).
