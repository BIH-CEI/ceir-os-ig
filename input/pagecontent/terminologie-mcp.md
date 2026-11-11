Der Terminology MCP Server ist der zentrale Terminologie-Zugang in CEIR-OS. Er bündelt den Zugriff auf mehrere Terminologie-Quellen in einer einheitlichen Schnittstelle.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `terminology-mcp` |
| Port 3000 | HTTP REST Proxy |
| Port 3002 | MCP SSE Endpunkt |
| Image | `ghcr.io/bih-cei/terminology-mcp/terminology-mcp:<Tag>` aus dem Repo `terminology-mcp`, Tag über `TERMINOLOGY_MCP_VERSION` in `.env`, lokal baubar |

Der Server stellt **zwei Schnittstellen** bereit:

- **Port 3000 (HTTP REST)**: Klassische HTTP-Endpunkte für Terminologie-Abfragen. Wird von der MCP Bridge und anderen Services genutzt.
- **Port 3002 (MCP SSE)**: Server-Sent Events Endpunkt für das Model Context Protocol. Wird von Claude Code und anderen MCP-Clients genutzt.

### CodeSystem-Index

Die folgende Tabelle zeigt alle über CEIR-OS verfügbaren CodeSystems mit der exakten `system`-URL für FHIR-Abfragen.

| CodeSystem | `system`-URL (für FHIR) | Quelle | Versionen | Offline |
|-----------|------------------------|--------|-----------|---------|
| SNOMED CT | `http://snomed.info/sct` | Snowstorm (lokal) | International 2025-12, DE + CH Editionen | Ja |
| LOINC | `http://loinc.org` | MII OntoServer (Haupttabelle) + Terminology MCP (vollständig, lokal) | OntoServer: v2.77–2.80; lokal: komplette Distribution + deutsche Labels, Panels, Answer Lists | Ja (lokal) |
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` | MII OntoServer (remote) | 2009–2025 (17 Versionen) | Nein |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` | MII OntoServer (remote) | Mehrere Jahresversionen | Nein |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` | MII OntoServer (remote) | Mehrere Jahresversionen | Nein |

> **Tipp:** Die `system`-URL ist der Wert, den du bei `validate_code`, `lookup_code` und `search_across_versions` als `system`-Parameter übergibst. Beispiel: `{"system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm", "code": "E11.9"}`.

#### Welches Tool für welches CodeSystem?

| Tool | SNOMED CT | LOINC | ICD-10-GM | OPS | ATC |
|------|-----------|-------|-----------|-----|-----|
| `validate_code` | x | x | x | x | x |
| `lookup_code` | x | x | x | x | x |
| `search_codes` | x | x | x | x | x |
| `search_common_loinc` | | x | | | |
| `get_german_label` | | x | | | |
| `search_across_versions` | | | x | x | x |
| `list_panels` | | x | | | |
| `get_panel_components` | | x | | | |
| `lookup_loinc_answer_code` | | x | | | |

### Unterstützte CodeSysteme nach Quelle

Der Terminology MCP Server bündelt drei verschiedene Terminologie-Quellen in einer einheitlichen Schnittstelle. Die Quelle bestimmt Verfügbarkeit, Latenz und Konfigurationsaufwand.

#### Lokal: Snowstorm (eigener FHIR TermServer)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| SNOMED CT | `http://snomed.info/sct` | FHIR R4 API via Snowstorm (Elasticsearch) |

- **Betrieb**: Eigener Container (`ceir-snowstorm`), benötigt Elasticsearch und SNOMED-RF2-Import
- **Bezug**: SNOMED CT ZIP-Datei wird teamintern bereitgestellt (wird direkt als Volume gemountet)
- **Geladene Editionen**: International (900000000000207008), DE-Edition (11000274103), CH-Edition (2011000195101)
- **Latenz**: Niedrig (lokales Netzwerk)
- **Offline-fähig**: Ja

#### Lokal: Dateibasiert (vorindexiert)

| CodeSystem | URL | Zugang |
|-----------|-----|--------|
| LOINC | `http://loinc.org` | Komplette LOINC-Distribution lokal im Terminology MCP |

- **Betrieb**: Die vollständige LOINC-Distribution wird beim Containerstart aus `LOINC_PATH` geladen
- **Lizenz**: [Regenstrief LOINC License](https://loinc.org/license/) (kostenlos nach Registrierung)
- **Umfang**: Komplettes LOINC mit deutschen Übersetzungen (soweit vorhanden), Panels und Answer Lists — deutlich mehr als die LOINC-Haupttabelle auf dem MII OntoServer
- **Latenz**: Sehr niedrig (In-Memory)
- **Offline-fähig**: Ja

> **Hinweis:** Auf dem MII OntoServer liegt nur die LOINC-Haupttabelle als CodeSystem (Versionen 2.77–2.80). Der Terminology MCP hat dagegen die komplette LOINC-Distribution lokal hinterlegt und bietet darüber Zugang zu den deutschen Übersetzungen (`get_german_label`), Panels (`list_panels`, `get_panel_components`) und Answer Lists (`lookup_loinc_answer_code`). Für LOINC-Abfragen sind die lokalen Tools daher immer vorzuziehen.

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

#### Weitere CodeSystems auf dem MII OntoServer

Der MII OntoServer stellt insgesamt **1.658 eindeutige CodeSystem-URLs** (1.792 Einträge inkl. Versionen) bereit. Die CEIR-OS Tools (`validate_code`, `lookup_code`, `search_codes`) können prinzipiell alle diese CodeSystems abfragen. Die folgende Tabelle zeigt die wichtigsten Kategorien:

| Kategorie | Anzahl URLs | Beispiele |
|-----------|-------------|-----------|
| HL7 Terminologien | 875 | `http://terminology.hl7.org/CodeSystem/...` (Admit Source, Condition Category, Observation Category etc.) |
| Sonstige (MII, HiGHmed, FDPG etc.) | 425 | MII KDS Module, HiGHmed Onkologie, FDPG Translations, GECCO, NUM |
| HL7 FHIR Core | 277 | `http://hl7.org/fhir/...` (Administrative Gender, Resource Types, Data Types etc.) |
| DE Basisprofil | 37 | `http://fhir.de/CodeSystem/...` (Kontaktebene, ASK, ABDATA, DKGeV, DEÜVAnlagen) |
| BfArM | 24 | ICD-10-GM (17 Versionen), OPS (16), ATC (8), Alpha-ID (11), plus Supplements |
| Ontologien | 16 | HPO, ORPHAcodes, Gene Ontology (GO), HGNC, Sequence Ontology, DICOM, UNII |
| SNOMED CT | 2 | International Edition + MII Supplement |
| LOINC | 1 | Versionen 2.77–2.80 |
| WHO | 1 | ICD-11 MMS |

> **Hinweis:** Die Tools `search_across_versions` und `search_common_loinc` sind für die Haupt-CodeSystems (ICD-10-GM, OPS, ATC bzw. LOINC) optimiert. Für alle anderen CodeSystems auf dem OntoServer kannst du `validate_code`, `lookup_code` und `search_codes` mit der jeweiligen `system`-URL verwenden.

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
| Client-Zertifikat | `certs/<Name>.pem` (z.B. `BIH-CEI_Team.pem`) | `CERT_CLIENT_PEM_B64` |
| Privater Schlüssel | `certs/<Name>.key` (gleicher Basisname) | `CERT_CLIENT_KEY_B64` |
| Root CA | `certs/rootca.pem` | `CERT_ROOT_CA_B64` |
| Intermediate CA | `certs/intermediate.pem` | `CERT_INTERMEDIATE_B64` |

Der Basisname des Client-Zertifikats wird ab terminology-mcp 1.1.2 automatisch erkannt (genau ein `<Name>.pem`/`<Name>.key`-Paar im Zertifikatsverzeichnis) oder über `CERT_CLIENT_NAME` gesetzt. SU-TermServ-Bundles können daher beim Zertifikatswechsel unverändert abgelegt werden; nur `CERT_PASSPHRASE` muss mitgezogen werden.

Die `CERT_PASSPHRASE` ist über teaminterne Kanäle zu beziehen (in beiden Varianten als Umgebungsvariable).

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
| `SNOWSTORM_SNOMED_VERSION` | `.../version/20261001` | Standard-Edition für SNOMED-Lookups, muss auf dem Snowstorm-Image existieren |
| `PROXY_SMART_ROUTING` | `true` | REST-Proxy routet wie die MCP-Tools; `false` = reiner OntoServer-Passthrough |
| `BLAZE_URL` | `http://blaze-full:8080/fhir` | Fallback bei nicht erreichbarem OntoServer (LOINC, SNOMED CT International) |
| `CERT_PASSPHRASE` | - | Teamintern bereitgestellt; Shell-Variablen schlagen `.env` |
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

# Backends: ontoserver / snowstorm / blaze erreichbar?
curl -s http://localhost:3000/ready | jq .backends
```

Beide Health-Endpunkte müssen antworten, damit der Container als gesund gilt. Jeder Aufruf über REST oder MCP landet im Call-Log `logs/terminology-mcp/terminology-calls.jsonl` mit Tool, Argumenten, Quelle, Trefferzahl und Dauer.

### Verfügbare Tools

Der Terminology MCP Server stellt 19 Tools bereit. Eine detaillierte Beschreibung der wichtigsten Tools mit Parametern und Beispielen findest du auf der Seite [Terminologie-Tools](terminologie-tools.html).
