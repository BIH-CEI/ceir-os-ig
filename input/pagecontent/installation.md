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

Öffne die `.env`-Datei und passe folgende Pfade an:

| Variable | Beschreibung | Beispiel |
|----------|-------------|---------|
| `SNOMED_PACKAGE_PATH` | Pfad zur SNOMED CT ZIP-Datei (wird direkt gemountet) | `/home/user/terminologies/snomed.zip` |
| `CERTS_PATH` | Verzeichnis mit mTLS-Zertifikaten | `./certs` |
| `LOINC_PATH` | Pfad zur LOINC-Distribution | `/home/user/terminologies/Loinc_2.81` |
| `ZOTERO_PATH` | Pfad zum Zotero Comfort Quellcode | `../../zotero_comfort/mayor/rig` |
| `ASKMII_PATH` | Pfad zum AskMII Quellcode | `../AskMIIAnything` |

### Schritt 3: SNOMED CT ZIP-Datei einbinden

Das SNOMED CT RF2-Paket liegt intern im BIH SharePoint. Du musst es **nicht** separat beschaffen.

1. Lade die SNOMED CT ZIP-Datei aus dem SharePoint herunter
2. Trage den Pfad zur ZIP-Datei in `SNOMED_PACKAGE_PATH` ein — die Datei wird direkt als Volume gemountet
3. Der SNOMED Unpacker entpackt die ZIP beim ersten Start automatisch

### Schritt 4: mTLS-Zertifikate für MII OntoServer

Für den Zugriff auf ICD-10-GM, OPS und ATC über den MII OntoServer benötigst du mTLS-Zertifikate. Es gibt zwei Optionen:

**Lokal: Volume-Mount (Standard)**

Zertifikatsdateien werden zur Laufzeit als Read-Only-Volume in den Container gemountet — sie sind nie im Image enthalten.

```bash
mkdir -p certs
# Lege folgende Dateien ab:
# certs/client.pem        - Client-Zertifikat
# certs/client.key         - Privater Schlüssel
# certs/root-ca.pem        - Root CA
# certs/intermediate.pem   - Intermediate CA
```

Die `CERT_PASSPHRASE` direkt bei Thomas Debertshäuser erfragen und in der `.env`-Datei eintragen.

**CI/CD: Base64-Umgebungsvariablen**

In CI/CD-Pipelines (z.B. GitHub Actions) können die Zertifikate stattdessen als Base64-kodierte Umgebungsvariablen übergeben werden. Der Container dekodiert sie beim Start.

```bash
# Zertifikate kodieren (einmalig)
base64 -i client.pem | tr -d '\n'
```

Die kodierten Werte werden als Secrets hinterlegt und über Umgebungsvariablen übergeben:
- `CERT_CLIENT_PEM_B64`
- `CERT_CLIENT_KEY_B64`
- `CERT_ROOT_CA_B64`
- `CERT_INTERMEDIATE_B64`

> **Hinweis:** Zertifikate sind in keinem Fall im Docker-Image enthalten. Lokal werden sie per Volume gemountet, in CI/CD per Umgebungsvariable injiziert.

### Schritt 5: LOINC-Daten herunterladen

1. Registriere dich bei [loinc.org](https://loinc.org/downloads/)
2. Lade die LOINC-Distribution herunter (z.B. `Loinc_2.81`)
3. Entpacke das Archiv und trage den Pfad in `LOINC_PATH` ein

Die LOINC-Daten werden für deutsche Labels, Panel-Informationen und Answer Lists verwendet.

### Schritt 6: Zotero API-Keys (optional)

Wenn du die Zotero-Literaturverwaltung nutzen möchtest:

1. Erstelle einen API-Key unter [zotero.org/settings/keys](https://www.zotero.org/settings/keys/new)
2. Trage die Werte in der `.env` ein:
   - `ZOTERO_GROUP_API_KEY` - für die Gruppen-Bibliothek
   - `ZOTERO_PERSONAL_API_KEY` - für die persönliche Bibliothek (optional)

### Schritt 7: Stack starten

```bash
docker compose up -d
```

Beim ersten Start passiert automatisch:

1. **Elasticsearch** startet und wird als healthy gemeldet
2. **SNOMED Unpacker** entpackt das SNOMED-Paket in das `sct_files`-Volume
3. **Snowstorm** startet und wartet auf Elasticsearch
4. **SNOMED Importer** lädt die SNOMED-Daten über die Snowstorm-API (kann 10-30 Minuten dauern)
5. **SNOMED Browser** wird gestartet, nachdem der Import abgeschlossen ist
6. **Ollama Init** lädt das Standard-Modell `qwen2.5:7b` herunter
7. Alle weiteren Services starten parallel

### Schritt 8: Verifizierung

Prüfe den Status aller Services:

```bash
docker compose ps
```

Health-Checks für einzelne Services:

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

Je nach Größe des SNOMED-Pakets muss der Elasticsearch-Speicher angepasst werden:

| Paketgröße | ES_JAVA_OPTS |
|-------------|-------------|
| Klein (< 500 MB) | `-Xms1g -Xmx1g` |
| Mittel (500 MB - 2 GB) | `-Xms2g -Xmx2g` |
| Groß (> 2 GB) | `-Xms4g -Xmx4g` |

Setze den Wert in der `.env`-Datei:

```env
ES_JAVA_OPTS="-Xms2g -Xmx2g"
```
