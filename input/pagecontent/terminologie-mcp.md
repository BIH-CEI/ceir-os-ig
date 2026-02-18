Der Terminology MCP Server ist der zentrale Terminologie-Zugang in CEIR-OS. Er buendelt den Zugriff auf mehrere Terminologie-Quellen in einer einheitlichen Schnittstelle.

### Uebersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-terminology-mcp` |
| Port 3000 | HTTP REST Proxy |
| Port 3002 | MCP SSE Endpunkt |
| Image | Eigener Build aus `terminology-proxy-mcp/` |

Der Server stellt **zwei Schnittstellen** bereit:

- **Port 3000 (HTTP REST)**: Klassische HTTP-Endpunkte fuer Terminologie-Abfragen. Wird von der MCP Bridge und anderen Services genutzt.
- **Port 3002 (MCP SSE)**: Server-Sent Events Endpunkt fuer das Model Context Protocol. Wird von Claude Code und anderen MCP-Clients genutzt.

### Unterstuetzte CodeSysteme nach Quelle

Der Terminology MCP Server buendelt drei verschiedene Terminologie-Quellen in einer einheitlichen Schnittstelle. Die Quelle bestimmt Verfuegbarkeit, Latenz und Konfigurationsaufwand.

#### Lokal: Snowstorm (eigener FHIR TermServer)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| SNOMED CT | `http://snomed.info/sct` | FHIR R4 API via Snowstorm (Elasticsearch) |

- **Betrieb**: Eigener Container (`ceir-snowstorm`), benoetigt Elasticsearch und SNOMED-RF2-Import
- **Lizenz**: SNOMED CT Affiliate License via [MLDS](https://mlds.ihtsdotools.org/)
- **Latenz**: Niedrig (lokales Netzwerk)
- **Offline-faehig**: Ja

#### Lokal: Dateibasiert (vorindexiert)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| LOINC | `http://loinc.org` | Lokale JSON-Indizes + LOINC-Linguistik-Dateien |

- **Betrieb**: Dateien werden beim Containerstart aus `LOINC_PATH` geladen
- **Lizenz**: [Regenstrief LOINC License](https://loinc.org/license/) (kostenlos nach Registrierung)
- **Besonderheit**: Deutsche Labels, Panels, Answer Lists — kein externer Server noetig
- **Latenz**: Sehr niedrig (In-Memory)
- **Offline-faehig**: Ja

#### Remote: MII OntoServer (mTLS-gesichert)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` | FHIR R4 API via MII Terminologieserver |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` | FHIR R4 API via MII Terminologieserver |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` | FHIR R4 API via MII Terminologieserver |

- **Betrieb**: Externer Server der Medizininformatik-Initiative, Zugang ueber mutual TLS (mTLS)
- **Lizenz**: BfArM-Terminologien, Zugang ueber MII-Mitgliedschaft
- **Besonderheit**: Versionsuebergreifende Suche (z.B. ICD-10-GM 2009–2025)
- **Latenz**: Mittel (Netzwerk-Roundtrip)
- **Offline-faehig**: Nein — erfordert Netzwerkverbindung und gueltige Zertifikate

### Routing-Logik

Der Terminology MCP Server routet Anfragen automatisch an die richtige Quelle:

```
Anfrage ──► system URL erkennen
            ├── snomed.info/sct     ──► Snowstorm (lokal, Port 8080)
            ├── loinc.org           ──► Lokale Dateien (In-Memory)
            └── fhir.de/CodeSystem/ ──► MII OntoServer (mTLS, remote)
```

### MII OntoServer Anbindung

Der Zugriff auf den MII OntoServer erfolgt ueber mutual TLS (mTLS). Dafuer werden folgende Zertifikate benoetigt:

| Zertifikat | Umgebungsvariable (Base64) | Datei im Verzeichnis |
|-----------|---------------------------|---------------------|
| Client-Zertifikat | `CERT_CLIENT_PEM_B64` | `certs/client.pem` |
| Privater Schluessel | `CERT_CLIENT_KEY_B64` | `certs/client.key` |
| Root CA | `CERT_ROOT_CA_B64` | `certs/root-ca.pem` |
| Intermediate CA | `CERT_INTERMEDIATE_B64` | `certs/intermediate.pem` |

Zusaetzlich muss `CERT_PASSPHRASE` gesetzt sein.

### Lokale LOINC-Daten

Die lokale LOINC-Suche bietet gegenueber Server-Abfragen mehrere Vorteile:

- **Deutsche Labels**: Uebersetzungen aus der offiziellen LOINC-Linguistik-Datei
- **Schnelle Suche**: Vorindexierte Daten, kein Netzwerk-Roundtrip
- **Panels**: Hierarchische Gruppierung von LOINC-Codes
- **Answer Lists**: Zuordnung von LOINC Answer Codes

Die Daten werden beim Containerstart aus dem gemounteten `LOINC_PATH`-Verzeichnis geladen.

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `SNOWSTORM_URL` | `http://snowstorm:8080/fhir` | Snowstorm FHIR-Endpunkt |
| `CERT_PASSPHRASE` | - | Passwort fuer mTLS-Zertifikate |
| `CERT_DIR` | `/app/certs` | Verzeichnis fuer Zertifikat-Dateien |
| `LOINC_DIR` | `/app/loinc` | Verzeichnis fuer LOINC-Daten |
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

Beide Endpunkte muessen healthy sein, damit der Container als gesund gilt.

### Verfuegbare Tools

Der Terminology MCP Server stellt 8 Tools bereit. Eine detaillierte Beschreibung aller Tools mit Parametern und Beispielen finden Sie auf der Seite [Terminologie-Tools](terminologie-tools.html).
