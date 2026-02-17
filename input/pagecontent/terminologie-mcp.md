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

### Unterstuetzte CodeSysteme

| CodeSystem | Quelle | URL |
|-----------|--------|-----|
| SNOMED CT | Snowstorm (lokal) | `http://snomed.info/sct` |
| LOINC | Lokale Dateien | `http://loinc.org` |
| ICD-10-GM | MII OntoServer (mTLS) | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | MII OntoServer (mTLS) | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | MII OntoServer (mTLS) | `http://fhir.de/CodeSystem/bfarm/atc` |

### Routing-Logik

Der Terminology MCP Server routet Anfragen automatisch an die richtige Quelle:

- **SNOMED CT**: Weiterleitung an Snowstorm (`http://snowstorm:8080/fhir`)
- **ICD-10-GM, OPS, ATC**: Weiterleitung an den MII OntoServer via mTLS
- **LOINC**: Lokale Suche in vorindexierten Dateien (deutsche Labels, Panels, Answer Lists)

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
