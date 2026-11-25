*Deutsche Fassung: [Anwendungsfälle](anwendungsfaelle.html)*

This page describes typical user groups and how they use CEIR-OS.

### Who uses CEIR-OS?

CEIR-OS is developed at the Berlin Institute of Health (BIH) in the Clinical Electronic Interoperability Research (CEIR) working group. The user groups have different entry points:

| Role | Primary services | Typical tasks |
|-------|-----------------|-------------------|
| FHIR profilers | Terminology MCP, Snowstorm, FHIR Spec MCP | Validate codes, check ValueSets, test profiles against terminologies |
| Researchers | Zotero Comfort, AskMII | Search literature, build FDPG queries, prepare publications |
| Data engineers | Terminology MCP, MCP Bridge | Create mappings between CodeSystems, check data quality |
| New team members | Open WebUI, terminology tools | Look up codes, get familiar with FHIR terminologies |

### Use cases

#### 1. Look up a SNOMED CT code

**Who:** All roles

```bash
# Via MCP tool (Claude Code)
# → lookup_code with system=http://snomed.info/sct and code=84114007

# Via HTTP (curl)
curl -s "http://localhost:8090/fhir/CodeSystem/\$lookup?system=http://snomed.info/sct&code=84114007" | jq '.parameter[] | select(.name=="display") | .valueString'
```

**Result:** `"Heart failure"` with all designations (EN, DE, FR, IT)

#### 2. Find the German LOINC name

**Who:** FHIR profilers, data engineers

```bash
# Via MCP tool (Claude Code)
# → get_german_label with code=8310-5

# Via HTTP (curl)
curl -s "http://localhost:3000/loinc/8310-5/german" | jq .germanLabel
```

**Result:** `"Körpertemperatur"`

#### 3. Validate an ICD-10-GM code

**Who:** FHIR profilers, data engineers

```bash
# Via MCP tool (Claude Code)
# → validate_code with system=http://fhir.de/CodeSystem/bfarm/icd-10-gm and code=E11.9

# Note: Requires mTLS certificates for the MII OntoServer
```

**Result:** Validation result with display text and version

#### 4. Find a LOINC panel and its components

**Who:** FHIR profilers

```bash
# Via MCP tool (Claude Code)
# → list_panels with query=blood gas
# → get_panel_components with code=24336-0

# Via HTTP (curl)
curl -s "http://localhost:3000/panels?query=blood+gas" | jq '.panels[:3]'
curl -s "http://localhost:3000/panels/24336-0/components" | jq '.components[:5]'
```

#### 5. Search ICD-10-GM across versions

**Who:** Data engineers, researchers

```bash
# Via MCP tool (Claude Code)
# → search_codes with system=http://fhir.de/CodeSystem/bfarm/icd-10-gm and term=Diabetes

# Note: Searches across all versions (2009-2025) and shows
# in which versions a code exists
```

#### 6. Collect literature for a publication

**Who:** Researchers

```bash
# Via MCP tool (Claude Code)
# → search_papers with query="FHIR implementation guide"
# → suggest_collection for thematic grouping
# → export_collection_bibtex for LaTeX export
```

#### 7. Build an FDPG query

**Who:** Researchers

```bash
# Via MCP tool (Claude Code)
# → AskMII tools for structured queries to the Forschungsdatenportal Gesundheit (German Portal for Medical Research Data)
```

#### 8. Ask free-form terminology questions (chat)

**Who:** New team members, all roles

Open [localhost:3080](http://localhost:3080) (Open WebUI) and ask questions in natural language:

- "What is the SNOMED code for heart failure?"
- "Which LOINC codes exist for blood pressure?"
- "Validate the ICD-10-GM code E11.9"

The local LLM uses the MCP Bridge to call the right tools automatically.

### Which tools do I need?

| Task | Tool | Service |
|---------|------|---------|
| Validate a code | `validate_code` | Terminology MCP |
| Retrieve code details | `lookup_code` | Terminology MCP |
| Search codes | `search_codes` | Terminology MCP |
| LOINC in German | `get_german_label` | Terminology MCP (local) |
| Quick LOINC search | `search_common_loinc` | Terminology MCP (local) |
| LOINC panels | `list_panels`, `get_panel_components` | Terminology MCP (local) |
| SNOMED hierarchy | ECL via Snowstorm | Snowstorm |
| Look up a FHIR resource | FHIR Spec MCP tools | FHIR Spec MCP |
| Search literature | `search_papers` | Zotero Comfort |
| FDPG queries | AskMII tools | AskMII |
