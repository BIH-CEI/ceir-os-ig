Diese Seite beschreibt alle 8 Tools des Terminology MCP Servers mit Parametern, Beispielen und Hinweisen zur Verwendung.

### Tool-Uebersicht

| Nr. | Tool | Beschreibung |
|-----|------|-------------|
| 1 | `validate_code` | Code in einem CodeSystem validieren |
| 2 | `lookup_code` | Details fuer einen bekannten Code abrufen |
| 3 | `search_common_loinc` | Schnelle lokale LOINC-Suche mit deutschen Labels |
| 4 | `get_german_label` | Deutsche LOINC-Uebersetzung |
| 5 | `search_across_versions` | Versionuebergreifende Suche (ICD-10-GM, OPS, ATC) |
| 6 | `list_panels` | LOINC-Panels auflisten |
| 7 | `get_panel_components` | Panel-Komponenten abrufen |
| 8 | `lookup_loinc_answer_code` | LOINC Answer Codes nachschlagen |

---

### 1. validate_code

Validiert, ob ein Code in einem gegebenen CodeSystem existiert.

**Parameter:**

| Parameter | Typ | Pflicht | Beschreibung |
|-----------|-----|---------|-------------|
| `system` | string | ja | CodeSystem-URL |
| `code` | string | ja | Zu validierender Code |

**Unterstuetzte CodeSystem-URLs:**

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

Ruft Details fuer einen bekannten Code ab: Display-Name, Properties und Uebersetzungen.

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

Schnelle lokale Suche in den haeufigsten LOINC-Codes mit deutschen Labels. Bevorzugtes Tool fuer LOINC-Suchen.

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

Liefert die deutsche Uebersetzung fuer einen LOINC-Code.

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

**Unterstuetzte Systeme:**

| System | URL |
|--------|-----|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` |

**Beispiel: ICD-10 Code fuer Diabetes**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm",
  "searchText": "Diabetes"
}
```

**Antwort (gekuerzt):**

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
      { "code": "E13.9", "display": "Sonstiger naeher bezeichneter Diabetes mellitus" }
    ]
  },
  "totalUniqueCodes": 42
}
```

**Beispiel: OPS Code fuer Appendektomie**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/ops",
  "searchText": "Appendektomie"
}
```

**Beispiel: ATC Code fuer Metformin**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/atc",
  "searchText": "Metformin"
}
```

**Tipp:** Verwenden Sie kurze Suchbegriffe. "Diabetes" liefert bessere Ergebnisse als "Diabetes mellitus Typ 2 ohne Komplikationen".

---

### 6. list_panels

Listet alle verfuegbaren LOINC-Panels auf.

**Parameter:** Keine

**Beispiel:**

```json
{}
```

**Antwort (gekuerzt):**

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

**Antwort (gekuerzt):**

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

Schlaegt Details zu einem LOINC Answer Code nach. Answer Codes werden in LOINC fuer standardisierte Antwortoptionen verwendet (z.B. bei Fragebögen).

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
| LOINC-Code suchen | `search_common_loinc` | "HbA1c", "Glucose", "Kreatinin" |
| ICD-10 Code suchen | `search_across_versions` | "Diabetes", "Pneumonie" |
| OPS Code suchen | `search_across_versions` | "Appendektomie", "Koloskopie" |
| ATC Code suchen | `search_across_versions` | "Metformin", "Ibuprofen" |
| Bekannten Code nachschlagen | `lookup_code` | SNOMED 84114007, LOINC 2160-0 |
| Deutsche LOINC-Uebersetzung | `get_german_label` | Code 2160-0 |
| Code validieren | `validate_code` | "Existiert E11.9 in ICD-10-GM?" |
| Laborpanel anzeigen | `list_panels` + `get_panel_components` | Panel 24323-8 |
