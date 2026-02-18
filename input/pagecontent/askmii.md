AskMII ist ein MCP-Server für den Aufbau von Abfragen an das Forschungsdatenportal Gesundheit (FDPG) der Medizininformatik-Initiative (MII).

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-ask-mii` |
| Port | 2026 |
| KDS-Version | 2026.0.0 |
| Protokoll | MCP (SSE) |

### Funktionsweise

AskMII unterstützt beim Erstellen von strukturierten Abfragen für das FDPG. Es kennt den Kerndatensatz (KDS) der MII und kann:

- Verfügbare Datenelemente im KDS nachschlagen
- Strukturierte Abfragen (Feasibility Queries) formulieren
- Kriterien-Kombinationen vorschlagen
- Kodierungen für Abfrage-Parameter identifizieren

### KDS (Kerndatensatz)

Der Kerndatensatz der MII definiert einheitliche Datenstrukturen für die medizinische Forschung. AskMII beinhaltet die KDS-Version 2026.0.0 und kennt Module wie:

- **Person**: Demographische Daten
- **Fall**: Einrichtungskontakte und Abteilungskontakte
- **Diagnose**: ICD-10-GM kodierte Diagnosen
- **Prozedur**: OPS-kodierte Prozeduren
- **Laborbefund**: LOINC-kodierte Laborwerte
- **Medikation**: ATC-kodierte Medikamente
- **Consent**: Einwilligungen

### Verwendung

#### Mit Claude Code

AskMII wird als MCP-Server direkt von Claude Code erkannt, wenn der SSE-Endpunkt konfiguriert ist:

```
Nutze AskMII, um eine Feasibility Query für alle Patienten
mit Diabetes mellitus Typ 2 (ICD-10 E11) und HbA1c > 7%
zu erstellen.
```

#### Mit OpenWebUI

Über die MCP Bridge wird AskMII automatisch in OpenWebUI verfügbar. Die Bridge entdeckt die AskMII-Tools beim Start und stellt sie als OpenAI-kompatible Functions bereit.

### Telemetrie

AskMII unterstützt optionale Telemetrie zur Nutzungsanalyse:

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `TELEMETRY_ENABLED` | `true` | Telemetrie aktivieren/deaktivieren |
| `TELEMETRY_URL` | - | Webhook-URL für Nutzungsdaten |
| `TELEMETRY_DATA_DIR` | `/app/data` | Verzeichnis für lokale Telemetrie-Daten |

Es werden nur leichtgewichtige Metriken gesendet: Tool-Name, Dauer und Erfolg (keine Inhalte).

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `ASKMII_PORT` | `2026` | Host-Port |
| `ASKMII_PATH` | `../AskMIIAnything` | Build-Kontext für Docker |
| `KDS_VERSION` | `2026.0.0` | KDS-Version |
| `MCP_TRANSPORT` | `sse` | Transportprotokoll |
| `MCP_HOST` | `0.0.0.0` | Bind-Adresse |

### Health Check

```bash
curl -s http://localhost:2026/health
```
