*Deutsche Fassung: [Terminologie-Tools](terminologie-tools.html)*

This page describes the most important of the 19 tools of the Terminology MCP Server, with parameters, examples and usage notes. `curl -s localhost:3000/tools | jq '.tools[].name'` returns the complete list.

### Tool Overview

The tools use different terminology sources (see [Terminology MCP Server](terminologie-mcp-en.html) for details):

| No. | Tool | Source | Description |
|-----|------|--------|-------------|
| 0 | `search_codes` | Snowstorm / MII | **Primary search** by display text in any CodeSystem, including LOINC and SNOMED CT; token filter: every search word must occur in the display, in any order |
| 1 | `validate_code` | Snowstorm / MII / Local | Validate a code in a CodeSystem |
| 2 | `lookup_code` | Snowstorm / MII / Local | Retrieve details for a known code |
| 3 | `search_common_loinc` | Local (files) | Secondary LOINC lookup: usage rank and German labels of the 20,000 most common codes |
| 4 | `get_german_label` | Local (files) | German LOINC translation |
| 5 | `search_across_versions` | Remote (MII OntoServer) | Cross-version search (ICD-10-GM, OPS, ATC) |
| 6 | `list_panels` | Local (files) | List LOINC panels |
| 7 | `get_panel_components` | Local (files) | Retrieve panel components |
| 8 | `lookup_loinc_answer_code` | Local (files) | Look up LOINC answer codes |

**Source legend:**
- **Snowstorm** = Local SNOMED CT FHIR server (its own container)
- **Local (files)** = Pre-indexed LOINC data inside the container (works offline)
- **Remote (MII OntoServer)** = External server of the Medical Informatics Initiative (mTLS, network required)

---

### 1. validate_code

Validates whether a code exists in a given CodeSystem.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `system` | string | yes | CodeSystem URL |
| `code` | string | yes | Code to validate |

**Supported CodeSystem URLs:**

| CodeSystem | URL |
|-----------|-----|
| SNOMED CT | `http://snomed.info/sct` |
| LOINC | `http://loinc.org` |
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` |

**Example:**

```json
{
  "system": "http://snomed.info/sct",
  "code": "84114007"
}
```

**Response:**

```json
{
  "result": true,
  "display": "Heart failure (disorder)"
}
```

---

### 2. lookup_code

Retrieves details for a known code: display name, properties and translations.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `system` | string | yes | CodeSystem URL |
| `code` | string | yes | The exact code |

**Example: SNOMED CT lookup**

```json
{
  "system": "http://snomed.info/sct",
  "code": "84114007"
}
```

**Response:**

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

**Example: LOINC lookup**

```json
{
  "system": "http://loinc.org",
  "code": "2160-0"
}
```

**Response:**

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

Local index of the roughly 20,000 most frequently used LOINC codes, with usage rank and German labels from the official deDE translation. Not a replacement for `search_codes`: many valid codes, such as most echocardiography measurements, are missing from the index, so 0 hits here mean nothing. Useful after a `search_codes` search to check which of several candidates is in common use, for German labels, and as an offline fallback.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | yes | Search term (German or English) |
| `limit` | integer | no | Maximum number of hits (default: 10) |

**Example:**

```json
{
  "searchText": "Kreatinin",
  "limit": 5
}
```

**Response:**

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

**Note:** This search is faster than a server round trip because it is based on pre-indexed local data.

---

### 4. get_german_label

Returns the German translation for a LOINC code.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `code` | string | yes | LOINC code |

**Example:**

```json
{
  "code": "2160-0"
}
```

**Response:**

```json
{
  "code": "2160-0",
  "germanLabel": "Kreatinin",
  "display": "Creatinine [Mass/volume] in Serum or Plasma"
}
```

---

### 5. search_across_versions

Searches several versions of a CodeSystem (ICD-10-GM, OPS or ATC). Finds codes even if they exist only in certain versions.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `system` | string | yes | CodeSystem URL (see below) |
| `searchText` | string | yes | Search term |

**Supported systems:**

| System | URL |
|--------|-----|
| ICD-10-GM | `http://fhir.de/CodeSystem/bfarm/icd-10-gm` |
| OPS | `http://fhir.de/CodeSystem/bfarm/ops` |
| ATC | `http://fhir.de/CodeSystem/bfarm/atc` |

**Example: ICD-10 code for diabetes**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/icd-10-gm",
  "searchText": "Diabetes"
}
```

**Response (abridged):**

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

**Example: OPS code for appendectomy**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/ops",
  "searchText": "Appendektomie"
}
```

**Example: ATC code for metformin**

```json
{
  "system": "http://fhir.de/CodeSystem/bfarm/atc",
  "searchText": "Metformin"
}
```

**Tip:** Use short search terms. "Diabetes" returns better results than "Diabetes mellitus Typ 2 ohne Komplikationen".

---

### 6. list_panels

Lists all available LOINC panels.

**Parameters:** None

**Example:**

```json
{}
```

**Response (abridged):**

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

Retrieves the components (member codes) of a LOINC panel.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `panelCode` | string | yes | LOINC panel code |

**Example:**

```json
{
  "panelCode": "24323-8"
}
```

**Response (abridged):**

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

Looks up details for a LOINC answer code. LOINC uses answer codes for standardized answer options (e.g., in questionnaires).

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `answerCode` | string | yes | LOINC answer code (e.g., `LA6576-8`) |

**Example:**

```json
{
  "answerCode": "LA6576-8"
}
```

**Response:**

```json
{
  "answerCode": "LA6576-8",
  "display": "Positive",
  "answerList": "LL360-9"
}
```

---

### Search Strategy Recommendations

| Scenario | Recommended tool | Example |
|----------|-----------------|---------|
| Search for a LOINC code | `search_codes` with `system: http://loinc.org`, English terms ("ejection fraction", "interventricular septum diastole") | then `search_common_loinc` for rank and German label |
| Search for a SNOMED CT concept | `search_codes` with `system: http://snomed.info/sct` | "atrial fibrillation" |
| Search for an ICD-10 code | `search_across_versions` | "Diabetes", "Pneumonie" |
| Search for an OPS code | `search_across_versions` | "Appendektomie", "Koloskopie" |
| Search for an ATC code | `search_across_versions` | "Metformin", "Ibuprofen" |
| Look up a known code | `lookup_code` | SNOMED 84114007, LOINC 2160-0 |
| German LOINC translation | `get_german_label` | Code 2160-0 |
| Validate a code | `validate_code` | "Does E11.9 exist in ICD-10-GM?" |
| Show a lab panel | `list_panels` + `get_panel_components` | Panel 24323-8 |
