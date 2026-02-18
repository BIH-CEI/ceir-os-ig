Der FHIR Spezifikations-Navigator ermöglicht den MCP-basierten Zugriff auf die FHIR R4 Spezifikation (v4.0.1). Er dient dazu, Ressourcen-Definitionen nachzuschlagen, Kardinalitäten zu prüfen und FHIR-Datentypen zu erkunden.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-fhir-spec-mcp` |
| Port | 8002 |
| Image | `ghcr.io/BIH-CEI/fhir-spec-mcp:latest` |
| FHIR-Version | 4.0.1 (R4) |
| Protokoll | MCP (SSE) |
| Repository | [github.com/BIH-CEI/fhir-spec-mcp](https://github.com/BIH-CEI/fhir-spec-mcp) |

### Funktionsweise

Der Server nutzt das FHIR R4 Package (`hl7.fhir.r4.core#4.0.1`) aus dem lokalen FHIR-Package-Cache (`~/.fhir/packages`). Dieser Cache wird automatisch befüllt, wenn lokal SUSHI oder das FHIR Terminal genutzt wurde. Das Volume `fhir-packages` mountet diesen Cache in den Container.

Die Daten liegen in zwei persistenten Volumes:
- `fhir-packages`: FHIR-Package-Cache (aus `~/.fhir/packages`)
- `fhir-cache`: Geparste Spezifikationsdaten für schnellen Zugriff

> **Voraussetzung:** Auf dem Host muss mindestens einmal `sushi` oder das FHIR Terminal gelaufen sein, damit `hl7.fhir.r4.core#4.0.1` im Package-Cache liegt.

Abfragen können sowohl über Claude Code als auch über die MCP Bridge (und damit OpenWebUI) genutzt werden.

### Verfügbare Tools

#### list_resources

Listet verfügbare FHIR-Ressourcen, Datentypen oder Extensions auf.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `kind` | string | Art der Ressourcen (`resource`, `datatype`, `extension`) |

#### get_elements

Liefert alle Elemente einer Ressource mit Kardinalität, Typen und Beschreibungen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource (z.B. `Patient`, `Observation`) |
| `include_inherited` | boolean | Geerbte Elemente einbeziehen |

#### get_required_elements

Liefert nur die Pflichtfelder (min>=1) einer Ressource.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |

#### get_references

Liefert Elemente, die auf andere Ressourcen verweisen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |

#### get_bindings

Liefert Elemente mit Terminologie-Bindings (ValueSets).

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |

#### get_element_detail

Liefert detaillierte Informationen zu einem bestimmten Element.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |
| `element_path` | string | Pfad des Elements (z.B. `Observation.value[x]`) |

#### get_resource_metadata

Liefert Metadaten einer Ressource (Scope, Maturity, Standards-Status).

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |

#### get_documentation

Ruft die narrative Dokumentation einer Ressource von hl7.org ab.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |
| `max_length` | integer | Maximale Länge der Dokumentation |

#### search_documentation

Durchsucht die Dokumentation einer Ressource nach bestimmten Begriffen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource` | string | Name der FHIR-Ressource |
| `query` | string | Suchbegriff |

#### compare_resources

Vergleicht die Elemente zweier Ressourcen.

**Parameter:**

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `resource1` | string | Name der ersten FHIR-Ressource |
| `resource2` | string | Name der zweiten FHIR-Ressource |

### Anwendungsfälle

- **Ressourcen-Definitionen nachschlagen**: Welche Elemente hat eine Observation? Welche sind Pflichtfelder?
- **Kardinalitäten prüfen**: Ist `Observation.value[x]` verpflichtend (1..1) oder optional (0..1)?
- **Datentypen erkunden**: Welche Choices gibt es für `value[x]` (valueQuantity, valueCodeableConcept, etc.)?
- **Profil-Entwicklung**: Welche Elemente können in einem Profil eingeschränkt werden?
- **Mapping-Unterstützung**: Welche FHIR-Elemente passen zu einem gegebenen klinischen Konzept?

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
