Diese Seite beschreibt die wichtigsten der 19 Tools des Terminology MCP Servers mit Parametern, Beispielen und Hinweisen zur Verwendung. Die vollständige Liste liefert `curl -s localhost:3000/tools | jq '.tools[].name'`.

### Tool-Übersicht

Die Tools nutzen unterschiedliche Terminologie-Quellen (siehe [Terminology MCP Server](terminologie-mcp.html) für Details):

| Nr. | Tool | Quelle | Beschreibung |
|-----|------|--------|-------------|
| 0 | `search_codes` | Snowstorm / MII | **Primäre Suche** nach Anzeigetext in jedem CodeSystem, auch LOINC und SNOMED CT; Token-Filter: jedes Suchwort muss im Display vorkommen, Reihenfolge egal |
| 1 | `validate_code` | Snowstorm / MII / Lokal | Code in einem CodeSystem validieren |
| 2 | `lookup_code` | Snowstorm / MII / Lokal | Details für einen bekannten Code abrufen |
| 3 | `search_common_loinc` | Lokal (Dateien) | Nachrangiger LOINC-Nachschlag: Nutzungsrang und deutsche Labels der 20.000 häufigsten Codes |
| 4 | `get_german_label` | Lokal (Dateien) | Deutsche LOINC-Übersetzung |
| 5 | `search_across_versions` | Remote (MII OntoServer) | Versionübergreifende Suche (ICD-10-GM, OPS, ATC) |
| 6 | `list_panels` | Lokal (Dateien) | LOINC-Panels auflisten |
| 7 | `get_panel_components` | Lokal (Dateien) | Panel-Komponenten abrufen |
| 8 | `lookup_loinc_answer_code` | Lokal (Dateien) | LOINC Answer Codes nachschlagen |

**Legende Quellen:**
- **Snowstorm** = Lokaler SNOMED CT FHIR Server (eigener Container)
- **Lokal (Dateien)** = Vorindexierte LOINC-Daten im Container (offline-fähig)
- **Remote (MII OntoServer)** = Externer Server der Medizininformatik-Initiative (mTLS, Netzwerk erforderlich)

---

### 1. validate_code

Validiert, ob ein Code in einem gegebenen CodeSystem existiert.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `system` | string | ja | CodeSystem-URL |
| `code` | string | ja | Zu validierender Code |

**Unterstützte CodeSystem-URLs:**

| CodeSystem | URL |
|-----------|-----|
| SNOMED CT | `http://snomed.info/sct` |
| LOINC | `http://loinc.org` |
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` |

**Beispiel:**

```json
{
  "system": "http://snomed.info/sct",
  "code": "84114007"
}
```

**Antwort:**

```json
{
  "result": true,
  "display": "Heart failure (disorder)"
}
```

---

### 2. lookup_code

Ruft Details für einen bekannten Code ab: Display-Name, Properties und Übersetzungen.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `system` | string | ja | CodeSystem-URL |
| `code` | string | ja | Der exakte Code |

**Beispiel: SNOMED CT Lookup**

```json
{
  "system": "http://snomed.info/sct",
  "code": "84114007"
}
```

**Antwort:**

```json
{
  "code": "84114007",
  "system": "http://snomed.info/sct",
  "display": "Heart failure (disorder)",
  "properties": {
    "parent": "56265001",
    "effectiveTime": "20020131"
  }
}
```

**Beispiel: LOINC Lookup**

```json
{
  "system": "http://loinc.org",
  "code": "2160-0"
}
```

**Antwort:**

```json
{
  "code": "2160-0",
  "system": "http://loinc.org",
  "display": "Creatinine [Mass/volume] in Serum or Plasma",
  "germanLabel": "Kreatinin",
  "component": "Creatinine",
  "property": "MCnc",
  "system_type": "Ser/Plas"
}
```

---

### 3. search_common_loinc

Lokaler Index der etwa 20.000 am häufigsten genutzten LOINC-Codes mit Nutzungsrang und deutschen Labels aus der offiziellen deDE-Übersetzung. Kein Ersatz für `search_codes`: viele gültige Codes, etwa die meisten Echokardiographie-Messungen, fehlen im Index, 0 Treffer hier heißen also nichts. Sinnvoll nach einer `search_codes`-Suche, um zu prüfen, welcher von mehreren Kandidaten gebräuchlich ist, für deutsche Labels und als Offline-Fallback.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `searchText` | string | ja | Suchbegriff (deutsch oder englisch) |
| `limit` | integer | nein | Maximale Treffer (Standard: 10) |

**Beispiel:**

```json
{
  "searchText": "Kreatinin",
  "limit": 5
}
```

**Antwort:**

```json
{
  "results": [
    {
      "code": "2160-0",
      "display": "Creatinine [Mass/volume] in Serum or Plasma",
      "germanLabel": "Kreatinin",
      "component": "Creatinine"
    },
    {
      "code": "14682-9",
      "display": "Creatinine [Moles/volume] in Serum or Plasma",
      "germanLabel": "Kreatinin",
      "component": "Creatinine"
    }
  ],
  "total": 2
}
```

**Hinweis:** Diese Suche ist schneller als ein Server-Roundtrip, da sie auf vorindexierten lokalen Daten basiert.

---

### 4. get_german_label

Liefert die deutsche Übersetzung für einen LOINC-Code.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `code` | string | ja | LOINC-Code |

**Beispiel:**

```json
{
  "code": "2160-0"
}
```

**Antwort:**

```json
{
  "code": "2160-0",
  "germanLabel": "Kreatinin",
  "display": "Creatinine [Mass/volume] in Serum or Plasma"
}
```

---

### 5. search_across_versions

Durchsucht mehrere Versionen eines CodeSystems (ICD-10-GM, OPS oder ATC). Findet Codes auch dann, wenn sie nur in bestimmten Versionen existieren.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `system` | string | ja | CodeSystem-URL (siehe unten) |
| `searchText` | string | ja | Suchbegriff |

**Unterstützte Systeme:**

| System | URL |
|--------|-----|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` |

**Beispiel: ICD-10 Code für Diabetes**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm",
  "searchText": "Diabetes"
}
```

**Antwort (gekürzt):**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm",
  "searchText": "Diabetes",
  "latestVersion": {
    "version": "2025",
    "count": 15,
    "codes": [
      { "code": "E10.9", "display": "Diabetes mellitus, Typ 1, ohne Komplikationen" },
      { "code": "E11.9", "display": "Diabetes mellitus, Typ 2, ohne Komplikationen" },
      { "code": "E13.9", "display": "Sonstiger näher bezeichneter Diabetes mellitus" }
    ]
  },
  "totalUniqueCodes": 42
}
```

**Beispiel: OPS Code für Appendektomie**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/ops",
  "searchText": "Appendektomie"
}
```

**Beispiel: ATC Code für Metformin**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/atc",
  "searchText": "Metformin"
}
```

**Tipp:** Verwende kurze Suchbegriffe. "Diabetes" liefert bessere Ergebnisse als "Diabetes mellitus Typ 2 ohne Komplikationen".

---

### 6. list_panels

Listet alle verfügbaren LOINC-Panels auf.

**Parameter:** Keine

**Beispiel:**

```json
{}
```

**Antwort (gekürzt):**

```json
{
  "panels": [
    { "code": "24323-8", "display": "Comprehensive metabolic 2000 panel" },
    { "code": "24356-8", "display": "Urinalysis complete panel" },
    { "code": "57021-8", "display": "CBC W Auto Differential panel" }
  ]
}
```

---

### 7. get_panel_components

Ruft die Komponenten (Member-Codes) eines LOINC-Panels ab.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `panelCode` | string | ja | LOINC-Panel-Code |

**Beispiel:**

```json
{
  "panelCode": "24323-8"
}
```

**Antwort (gekürzt):**

```json
{
  "panelCode": "24323-8",
  "panelDisplay": "Comprehensive metabolic 2000 panel",
  "components": [
    { "code": "2160-0", "display": "Creatinine [Mass/volume] in Serum or Plasma" },
    { "code": "2345-7", "display": "Glucose [Mass/volume] in Serum or Plasma" },
    { "code": "17861-6", "display": "Calcium [Mass/volume] in Serum or Plasma" }
  ]
}
```

---

### 8. lookup_loinc_answer_code

Schlägt Details zu einem LOINC Answer Code nach. Answer Codes werden in LOINC für standardisierte Antwortoptionen verwendet (z.B. bei Fragebögen).

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `answerCode` | string | ja | LOINC Answer Code (z.B. `LA6576-8`) |

**Beispiel:**

```json
{
  "answerCode": "LA6576-8"
}
```

**Antwort:**

```json
{
  "answerCode": "LA6576-8",
  "display": "Positive",
  "answerList": "LL360-9"
}
```

---

### Suchstrategie-Empfehlungen

| Szenario | Empfohlenes Tool | Beispiel |
|----------|-----------------|---------|
| LOINC-Code suchen | `search_codes` mit `system: http://loinc.org`, englische Begriffe ("ejection fraction", "interventricular septum diastole") | danach `search_common_loinc` für Rang und deutsches Label |
| SNOMED-CT-Konzept suchen | `search_codes` mit `system: http://snomed.info/sct` | "atrial fibrillation" |
| ICD-10 Code suchen | `search_across_versions` | "Diabetes", "Pneumonie" |
| OPS Code suchen | `search_across_versions` | "Appendektomie", "Koloskopie" |
| ATC Code suchen | `search_across_versions` | "Metformin", "Ibuprofen" |
| Bekannten Code nachschlagen | `lookup_code` | SNOMED 84114007, LOINC 2160-0 |
| Deutsche LOINC-Übersetzung | `get_german_label` | Code 2160-0 |
| Code validieren | `validate_code` | "Existiert E11.9 in ICD-10-GM?" |
| Laborpanel anzeigen | `list_panels` + `get_panel_components` | Panel 24323-8 |
