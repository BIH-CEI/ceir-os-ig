Der FHIR Spezifikations-Navigator ermoeglicht den MCP-basierten Zugriff auf die FHIR R4 Spezifikation (v4.0.1). Er dient dazu, Ressourcen-Definitionen nachzuschlagen, Kardinalitaeten zu pruefen und FHIR-Datentypen zu erkunden.

### Uebersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-fhir-spec-mcp` |
| Port | 8002 |
| Image | `ghcr.io/BIH-CEI/fhir-spec-mcp:latest` |
| FHIR-Version | 4.0.1 (R4) |
| Protokoll | MCP (SSE) |

### Funktionsweise

Der FHIR Spec MCP Server laedt die FHIR R4 Spezifikation beim Start und stellt sie ueber MCP-Tools bereit. Abfragen koennen sowohl ueber Claude Code als auch ueber die MCP Bridge (und damit OpenWebUI) genutzt werden.

Die Spezifikationsdaten werden in zwei persistenten Volumes gecacht:
- `fhir-cache`: Cache der FHIR-Spezifikationsdaten
- `fhir-packages`: FHIR-Paket-Cache

### Verfuegbare Tools

#### get_resource_definition

Liefert die vollstaendige Definition einer FHIR-Ressource inklusive aller Elemente, Kardinalitaeten und Datentypen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource_name` | string | Name der FHIR-Ressource (z.B. `Patient`, `Observation`, `Condition`) |

**Beispiel:**

```
get_resource_definition(resource_name="Observation")
```

Liefert die Struktur-Definition fuer Observation mit allen Elementen wie `status`, `code`, `value[x]`, `subject`, `effectiveDateTime` etc.

#### search_fhir_spec

Durchsucht die FHIR-Spezifikation nach Begriffen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `query` | string | Suchbegriff (z.B. `blood pressure`, `medication`, `allergy`) |

**Beispiel:**

```
search_fhir_spec(query="vital signs")
```

### Anwendungsfaelle

- **Ressourcen-Definitionen nachschlagen**: Welche Elemente hat eine Observation? Welche sind Pflichtfelder?
- **Kardinalitaeten pruefen**: Ist `Observation.value[x]` verpflichtend (1..1) oder optional (0..1)?
- **Datentypen erkunden**: Welche Choices gibt es fuer `value[x]` (valueQuantity, valueCodeableConcept, etc.)?
- **Profil-Entwicklung**: Welche Elemente koennen in einem Profil eingeschraenkt werden?
- **Mapping-Unterstuetzung**: Welche FHIR-Elemente passen zu einem gegebenen klinischen Konzept?

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `FHIR_SPEC_MCP_PORT` | `8002` | Host-Port |
| `FHIR_SPEC_VERSION` | `4.0.1` | FHIR-Version |
| `LOG_LEVEL` | `info` | Log-Level |

### Health Check

```bash
curl -s http://localhost:8002/health
```
