*Deutsche Fassung: [BabelFSH](babelfsh.html)*

BabelFSH is a tool of the Medical Informatics Initiative that converts terminological artifacts (CSV, Excel, OWL, ClaML etc.) into FHIR CodeSystem resources. It uses FSH (FHIR Shorthand) as its input format and a plugin architecture for different source formats.

### Overview

| Property | Value |
|------------|------|
| Repository | [gitlab.com/mii-termserv/babelfsh](https://gitlab.com/mii-termserv/babelfsh) |
| Documentation | [su-termserv.gitbook.io/babelfsh](https://su-termserv.gitbook.io/babelfsh) |
| Prerequisite | Java 21 |
| File format | `.babel.fsh` or `.babelfsh.fsh` |

### Available plugins

BabelFSH supports 11 plugins for different terminology formats:

| Plugin | Description | Typical use |
|--------|-------------|-------------------|
| `csv` | CSV files with column mapping | Custom terminologies, tabular data |
| `excel` | MS Excel (.xlsx) | Excel-based terminologies |
| `owl` | OWL ontologies via fhir-owl | HPO, SNOMED, ontologies |
| `claml-standard` | Standard ClaML files | ICD-10, ICD-11 |
| `claml-bfarm` | BfArM-specific ClaML | ICD-10-GM, OPS, Alpha-ID |
| `atc-ddd` | ATC/DDD Excel from WIdO | German ATC classification |
| `orphacodes` | ORPHAcodes nomenclature | Rare diseases |
| `edqm` | EDQM Standard Terms API | Pharmaceutical terms |
| `unii` | FDA UNII Master Files | Substance identifiers |
| `iso-country-codes` | ISO-3166 Part 1 | Country codes |
| `xslt` | XML with XSLT transformation | Custom XML formats |

Most frequently used: `csv` and `excel` for custom terminologies.

### When to use BabelFSH?

**Suitable:**
- Wide-format CSV/Excel (one row = one concept)
- Properties with simple types: `code`, `string`, `boolean`, `integer`
- Standard terminology formats (ClaML, OWL, EDQM etc.)
- Multiple versions with shared metadata (RuleSets)

**Not suitable:**
- Long-format data (multiple rows per concept): transform it with Python first
- Properties of type `Coding` or `CodeableConcept`: use the Python→FSH→SUSHI workflow
- Complex transformation logic or nested hierarchies

### Basic structure of a BabelFSH file

```fsh
CodeSystem: MeineTerminologie
Id: meine-terminologie
Title: "Meine Terminologie"
Description: "Beschreibung des CodeSystems"

* ^url = "https://example.org/fhir/CodeSystem/meine-terminologie"
* ^version = "2025"
* ^status = #active
* ^content = #complete
* ^publisher = "Organisation"

// Property definitions
* ^property[+].code = #status
* ^property[=].type = #code
* ^property[=].description = "Konzept-Status"

// BabelFSH plugin configuration
/*^babelfsh
csv --path='./input-files/daten.csv'
    --code-column=code
    --display-column=display
    --definition-column=definition
    --property-mapping=[{"column":"status","property":"status"}]
^babelfsh*/
```

### Example: CSV with properties

**daten.csv:**

```csv
code,display,definition,status,category
LAB-001,Glucose Test,Blutzuckermessung,active,labor
LAB-002,HbA1c,Langzeit-Blutzucker,active,labor
```

**labor-tests.babel.fsh:**

```fsh
CodeSystem: LaborTests
Id: labor-tests
Title: "Labortests"
Description: "Häufige Labortests"
* ^url = "https://example.org/fhir/CodeSystem/labor-tests"
* ^version = "2025"
* ^status = #active
* ^content = #complete

* ^property[+].code = #status
* ^property[=].type = #code
* ^property[=].description = "Konzept-Status"

* ^property[+].code = #category
* ^property[=].type = #string
* ^property[=].description = "Test-Kategorie"

/*^babelfsh
csv --path='./input-files/daten.csv'
    --code-column=code
    --display-column=display
    --definition-column=definition
    --property-mapping=[
      {"column":"status","property":"status"},
      {"column":"category","property":"category"}
    ]
^babelfsh*/
```

### Running BabelFSH

```bash
# Clone and build the repository (Java 21 required)
git clone https://gitlab.com/mii-termserv/babelfsh.git
cd babelfsh
./gradlew installDist

# Convert a single file
./app/build/install/babelfsh/bin/babelfsh convert meine-terminologie.babel.fsh

# All files in the directory
./app/build/install/babelfsh/bin/babelfsh convert input/fsh/

# Check the result
cat fsh-generated/resources/CodeSystem-meine-terminologie.json | jq '.concept | length'
```

### Multiple versions with RuleSets

For terminologies with multiple yearly versions, you can use RuleSets to share common metadata:

```fsh
RuleSet: icd10gm-metadata
* ^url = "http://fhir.de/CodeSystem/bfarm/icd-10-gm"
* ^status = #active
* ^publisher = "BfArM"

RuleSet: icd10gm-babelfsh(version, filepath)
* ^version = "{version}"
* insert icd10gm-metadata
/*^babelfsh
claml-bfarm --path='{filepath}'
^babelfsh*/

CodeSystem: ICD10GM2024
Id: icd10gm-2024
Title: "ICD-10-GM 2024"
Description: "ICD-10-GM Version 2024"
* insert icd10gm-babelfsh("2024", "./input-files/icd10gm2024.xml")

CodeSystem: ICD10GM2025
Id: icd10gm-2025
Title: "ICD-10-GM 2025"
Description: "ICD-10-GM Version 2025"
* insert icd10gm-babelfsh("2025", "./input-files/icd10gm2025.xml")
```

### Common problems

| Problem | Cause | Solution |
|---------|---------|--------|
| "Property type X not found" | Property not defined in FSH | Add `^property[+].code` |
| "Column not found" | Column name does not match (case-sensitive) | Check the CSV header or set `--headers` |
| Duplicate codes | Multiple rows with the same code | `--no-filter-duplicates` or clean up the CSV |
| Wrong special characters | Encoding problem | Set `--charset=UTF-8` |
| Empty CodeSystem | CSV structure cannot be parsed | Check wide format, check delimiter |

### Integration with CEIR-OS

BabelFSH complements the terminology tools of CEIR-OS:

1. **Create custom CodeSystems** with BabelFSH from CSV/Excel
2. **Validate codes** with `validate_code` via the [Terminology MCP Server](terminologie-mcp-en.html)
3. **Create mappings** with ConceptMaps (see [FHIR Mappings](fhir-mappings-en.html))
4. **Test profiles** with the [FHIR Specification Navigator](fhir-spec-mcp-en.html)

### Further resources

- [BabelFSH Repository](https://gitlab.com/mii-termserv/babelfsh)
- [BabelFSH Documentation](https://su-termserv.gitbook.io/babelfsh)
- [CSV Plugin Reference](https://su-termserv.gitbook.io/babelfsh/plugin-docs/codesystem/csv)
- [FHIR CodeSystem Specification](https://www.hl7.org/fhir/codesystem.html)
- [FSH Specification](https://hl7.org/fhir/uv/shorthand/)
