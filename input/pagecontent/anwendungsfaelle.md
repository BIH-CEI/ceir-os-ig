Diese Seite beschreibt typische Nutzergruppen und wie sie CEIR-OS einsetzen.

### Wer nutzt CEIR-OS?

CEIR-OS wird am Berlin Institute of Health (BIH) in der Arbeitsgruppe Clinical Electronic Interoperability Research (CEIR) entwickelt. Die Nutzergruppen haben unterschiedliche Einstiegspunkte:

| Rolle | Primäre Services | Typische Aufgaben |
|-------|-----------------|-------------------|
| FHIR-Profilierer | Terminology MCP, Snowstorm, FHIR Spec MCP | Codes validieren, ValueSets prüfen, Profile gegen Terminologien testen |
| Forschende | Zotero Comfort, AskMII | Literatur suchen, FDPG-Queries bauen, Publikationen vorbereiten |
| Dateningenieur | Terminology MCP, MCP Bridge | Mappings zwischen CodeSystemen erstellen, Datenqualität prüfen |
| Neue Teammitglieder | Open WebUI, Terminologie-Tools | Codes nachschlagen, sich mit FHIR-Terminologien vertraut machen |

### Anwendungsfälle

#### 1. SNOMED CT Code nachschlagen

**Wer:** Alle Rollen

```bash
# Per MCP-Tool (Claude Code)
# → lookup_code mit system=http://snomed.info/sct und code=84114007

# Per HTTP (curl)
curl -s "http://localhost:8090/fhir/CodeSystem/\$lookup?system=http://snomed.info/sct&code=84114007" | jq '.parameter[] | select(.name=="display") | .valueString'
```

**Ergebnis:** `"Heart failure"` mit allen Designations (EN, DE, FR, IT)

#### 2. Deutschen LOINC-Namen finden

**Wer:** FHIR-Profilierer, Dateningenieure

```bash
# Per MCP-Tool (Claude Code)
# → get_german_label mit code=8310-5

# Per HTTP (curl)
curl -s "http://localhost:3000/loinc/8310-5/german" | jq .germanLabel
```

**Ergebnis:** `"Körpertemperatur"`

#### 3. ICD-10-GM Code validieren

**Wer:** FHIR-Profilierer, Dateningenieure

```bash
# Per MCP-Tool (Claude Code)
# → validate_code mit system=http://fhir.de/CodeSystem/bfarm/icd-10-gm und code=E11.9

# Hinweis: Erfordert mTLS-Zertifikate für den MII OntoServer
```

**Ergebnis:** Validierungsergebnis mit Display-Text und Version

#### 4. LOINC-Panel und dessen Komponenten finden

**Wer:** FHIR-Profilierer

```bash
# Per MCP-Tool (Claude Code)
# → list_panels mit query=blood gas
# → get_panel_components mit code=24336-0

# Per HTTP (curl)
curl -s "http://localhost:3000/panels?query=blood+gas" | jq '.panels[:3]'
curl -s "http://localhost:3000/panels/24336-0/components" | jq '.components[:5]'
```

#### 5. Versionsübergreifend nach ICD-10-GM suchen

**Wer:** Dateningenieure, Forschende

```bash
# Per MCP-Tool (Claude Code)
# → search_codes mit system=http://fhir.de/CodeSystem/bfarm/icd-10-gm und term=Diabetes

# Hinweis: Sucht über alle Versionen (2009-2025) und zeigt,
# in welchen Versionen ein Code existiert
```

#### 6. Literatur für eine Publikation sammeln

**Wer:** Forschende

```bash
# Per MCP-Tool (Claude Code)
# → search_papers mit query="FHIR implementation guide"
# → suggest_collection für thematische Gruppierung
# → export_collection_bibtex für LaTeX-Export
```

#### 7. FDPG-Query bauen

**Wer:** Forschende

```bash
# Per MCP-Tool (Claude Code)
# → AskMII-Tools für strukturierte Abfragen am Forschungsdatenportal Gesundheit
```

#### 8. Freie Terminologie-Fragen stellen (Chat)

**Wer:** Neue Teammitglieder, alle Rollen

Öffne [localhost:3080](http://localhost:3080) (Open WebUI) und stelle Fragen in natürlicher Sprache:

- "Was ist der SNOMED-Code für Herzinsuffizienz?"
- "Welche LOINC-Codes gibt es für Blutdruck?"
- "Validiere den ICD-10-GM Code E11.9"

Das lokale LLM nutzt die MCP Bridge, um automatisch die richtigen Tools aufzurufen.

### Welche Tools brauche ich?

| Aufgabe | Tool | Service |
|---------|------|---------|
| Code validieren | `validate_code` | Terminology MCP |
| Code-Details abrufen | `lookup_code` | Terminology MCP |
| Codes suchen | `search_codes` | Terminology MCP |
| LOINC deutsch | `get_german_label` | Terminology MCP (lokal) |
| LOINC schnell suchen | `search_common_loinc` | Terminology MCP (lokal) |
| LOINC Panels | `list_panels`, `get_panel_components` | Terminology MCP (lokal) |
| SNOMED Hierarchie | ECL via Snowstorm | Snowstorm |
| FHIR-Ressource nachschlagen | FHIR Spec MCP Tools | FHIR Spec MCP |
| Literatur suchen | `search_papers` | Zotero Comfort |
| FDPG-Abfragen | AskMII Tools | AskMII |
