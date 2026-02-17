Diese Seite beschreibt die Installation und Ersteinrichtung von CEIR-OS.

### Voraussetzungen

| Komponente | Mindestanforderung |
|------------|-------------------|
| Docker | Version 24+ mit Docker Compose v2 |
| RAM | Mindestens 8 GB (empfohlen: 16 GB) |
| Festplatte | Mindestens 20 GB frei (SNOMED CT Index + Modelle) |
| Betriebssystem | Linux, macOS oder Windows mit WSL2 |

### Schritt 1: Repository klonen

```bash
git clone https://github.com/BIH-CEI/ceir-os.git
cd ceir-os
```

### Schritt 2: Konfiguration erstellen

```bash
cp .env.example .env
```

Oeffnen Sie die `.env`-Datei und passen Sie folgende Pfade an:

| Variable | Beschreibung | Beispiel |
|----------|-------------|---------|
| `SNOMED_PACKAGE_PATH` | Pfad zur SNOMED CT ZIP-Datei | `/home/user/terminologies/snomed.zip` |
| `TERMINOLOGY_PROXY_PATH` | Pfad zum Terminology-MCP-Quellcode | `./terminology-proxy-mcp` |
| `CERTS_PATH` | Verzeichnis mit mTLS-Zertifikaten | `./certs` |
| `LOINC_PATH` | Pfad zur LOINC-Distribution | `/home/user/terminologies/Loinc_2.81` |
| `ZOTERO_PATH` | Pfad zum Zotero Comfort Quellcode | `../../zotero_comfort/mayor/rig` |
| `ASKMII_PATH` | Pfad zum AskMII Quellcode | `../AskMIIAnything` |

### Schritt 3: SNOMED CT Paket beschaffen

SNOMED CT ist lizenzpflichtig. Sie benoetigen eine Lizenz ueber [MLDS (Member Licensing & Distribution Service)](https://mlds.ihtsdotools.org/).

1. Registrieren Sie sich bei MLDS
2. Laden Sie das gewuenschte SNOMED CT RF2-Paket herunter (z.B. International Edition oder SNOMED CT German Extension)
3. Speichern Sie die ZIP-Datei und tragen Sie den Pfad in `SNOMED_PACKAGE_PATH` ein

### Schritt 4: mTLS-Zertifikate fuer MII OntoServer

Fuer den Zugriff auf ICD-10-GM, OPS und ATC ueber den MII OntoServer benoetigen Sie mTLS-Zertifikate. Es gibt zwei Optionen:

**Option A: Dateien im Verzeichnis**

```bash
mkdir -p certs
# Legen Sie folgende Dateien ab:
# certs/client.pem    - Client-Zertifikat
# certs/client.key    - Privater Schluessel
# certs/root-ca.pem   - Root CA
# certs/intermediate.pem - Intermediate CA
```

Setzen Sie `CERT_PASSPHRASE` in der `.env`-Datei.

**Option B: Base64-kodierte Umgebungsvariablen**

```bash
# Zertifikate als Base64 kodieren
base64 -i client.pem | tr -d '\n'
```

Tragen Sie die kodierten Werte in die `.env`-Datei ein:
- `CERT_CLIENT_PEM_B64`
- `CERT_CLIENT_KEY_B64`
- `CERT_ROOT_CA_B64`
- `CERT_INTERMEDIATE_B64`

### Schritt 5: LOINC-Daten herunterladen

1. Registrieren Sie sich bei [loinc.org](https://loinc.org/downloads/)
2. Laden Sie die LOINC-Distribution herunter (z.B. `Loinc_2.81`)
3. Entpacken Sie das Archiv und tragen Sie den Pfad in `LOINC_PATH` ein

Die LOINC-Daten werden fuer deutsche Labels, Panel-Informationen und Answer Lists verwendet.

### Schritt 6: Zotero API-Keys (optional)

Wenn Sie die Zotero-Literaturverwaltung nutzen moechten:

1. Erstellen Sie einen API-Key unter [zotero.org/settings/keys](https://www.zotero.org/settings/keys/new)
2. Tragen Sie die Werte in der `.env` ein:
   - `ZOTERO_GROUP_API_KEY` - fuer die Gruppen-Bibliothek
   - `ZOTERO_PERSONAL_API_KEY` - fuer die persoenliche Bibliothek (optional)

### Schritt 7: Stack starten

```bash
docker compose up -d
```

Beim ersten Start passiert automatisch:

1. **Elasticsearch** startet und wird als healthy gemeldet
2. **SNOMED Unpacker** entpackt das SNOMED-Paket in das `sct_files`-Volume
3. **Snowstorm** startet und wartet auf Elasticsearch
4. **SNOMED Importer** laedt die SNOMED-Daten ueber die Snowstorm-API (kann 10-30 Minuten dauern)
5. **SNOMED Browser** wird gestartet, nachdem der Import abgeschlossen ist
6. **Ollama Init** laedt das Standard-Modell `qwen2.5:7b` herunter
7. Alle weiteren Services starten parallel

### Schritt 8: Verifizierung

Pruefen Sie den Status aller Services:

```bash
docker compose ps
```

Health-Checks fuer einzelne Services:

```bash
# Elasticsearch
curl -s http://localhost:9200/_cluster/health | jq .status

# Snowstorm
curl -s http://localhost:8090/fhir/metadata | jq .software

# Terminology MCP (HTTP Proxy)
curl -s http://localhost:3000/health

# Terminology MCP (MCP SSE)
curl -s http://localhost:3002/health

# AskMII
curl -s http://localhost:2026/health

# MCP Bridge
curl -s http://localhost:8000/health

# Ollama
curl -s http://localhost:11434

# Open WebUI
curl -s http://localhost:3080
```

### Elasticsearch-Speicher anpassen

Je nach Groesse des SNOMED-Pakets muss der Elasticsearch-Speicher angepasst werden:

| Paketgroesse | ES_JAVA_OPTS |
|-------------|-------------|
| Klein (< 500 MB) | `-Xms1g -Xmx1g` |
| Mittel (500 MB - 2 GB) | `-Xms2g -Xmx2g` |
| Gross (> 2 GB) | `-Xms4g -Xmx4g` |

Setzen Sie den Wert in der `.env`-Datei:

```env
ES_JAVA_OPTS="-Xms2g -Xmx2g"
```
