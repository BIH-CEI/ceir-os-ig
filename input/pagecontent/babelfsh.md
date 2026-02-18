BabelFSH ist ein Tool der Medizininformatik-Initiative, das terminologische Artefakte (CSV, Excel, OWL, ClaML etc.) in FHIR CodeSystem-Ressourcen konvertiert. Es nutzt FSH (FHIR Shorthand) als Eingabeformat und eine Plugin-Architektur für verschiedene Quellformate.

### Übersicht

| Eigenschaft | Wert |
|------------|------|
| Repository | [gitlab.com/mii-termserv/babelfsh](https://gitlab.com/mii-termserv/babelfsh) |
| Dokumentation | [su-termserv.gitbook.io/babelfsh](https://su-termserv.gitbook.io/babelfsh) |
| Voraussetzung | Java 21 |
| Dateiformat | `.babel.fsh` oder `.babelfsh.fsh` |

### Verfügbare Plugins

BabelFSH unterstützt 11 Plugins für unterschiedliche Terminologie-Formate:

| Plugin | Beschreibung | Typischer Einsatz |
|--------|-------------|-------------------|
| `csv` | CSV-Dateien mit Spalten-Mapping | Eigene Terminologien, tabellarische Daten |
| `excel` | MS Excel (.xlsx) | Excel-basierte Terminologien |
| `owl` | OWL-Ontologien via fhir-owl | HPO, SNOMED, Ontologien |
| `claml-standard` | Standard-ClaML-Dateien | ICD-10, ICD-11 |
| `claml-bfarm` | BfArM-spezifisches ClaML | ICD-10-GM, OPS, Alpha-ID |
| `atc-ddd` | ATC/DDD Excel von WIdO | Deutsche ATC-Klassifikation |
| `orphacodes` | ORPHAcodes-Nomenklatur | Seltene Erkrankungen |
| `edqm` | EDQM Standard Terms API | Pharmazeutische Begriffe |
| `unii` | FDA UNII Master Files | Wirkstoff-Identifikatoren |
| `iso-country-codes` | ISO-3166 Part 1 | Ländercodes |
| `xslt` | XML mit XSLT-Transformation | Eigene XML-Formate |

Am häufigsten genutzt: `csv` und `excel` für eigene Terminologien.

### Wann BabelFSH nutzen?

**Geeignet:**
- Wide-Format CSV/Excel (eine Zeile = ein Konzept)
- Properties mit einfachen Typen: `code`, `string`, `boolean`, `integer`
- Standard-Terminologieformate (ClaML, OWL, EDQM etc.)
- Mehrere Versionen mit gemeinsamen Metadaten (RuleSets)

**Nicht geeignet:**
- Long-Format-Daten (mehrere Zeilen pro Konzept) — vorher mit Python transformieren
- Properties vom Typ `Coding` oder `CodeableConcept` — Python→FSH→SUSHI Workflow verwenden
- Komplexe Transformationslogik oder verschachtelte Hierarchien

### Grundstruktur einer BabelFSH-Datei

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

// Property-Definitionen
* ^property[+].code = #status
* ^property[=].type = #code
* ^property[=].description = "Konzept-Status"

// BabelFSH Plugin-Konfiguration
/*^babelfsh
csv --path='./input-files/daten.csv'
    --code-column=code
    --display-column=display
    --definition-column=definition
    --property-mapping=[{"column":"status","property":"status"}]
^babelfsh*/
```

### Beispiel: CSV mit Properties

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

### BabelFSH ausführen

```bash
# Repository klonen und bauen (Java 21 erforderlich)
git clone https://gitlab.com/mii-termserv/babelfsh.git
cd babelfsh
./gradlew installDist

# Einzelne Datei konvertieren
./app/build/install/babelfsh/bin/babelfsh convert meine-terminologie.babel.fsh

# Alle Dateien im Verzeichnis
./app/build/install/babelfsh/bin/babelfsh convert input/fsh/

# Ergebnis prüfen
cat fsh-generated/resources/CodeSystem-meine-terminologie.json | jq '.concept | length'
```

### Mehrere Versionen mit RuleSets

Für Terminologien mit mehreren Jahresversionen kannst du RuleSets verwenden, um gemeinsame Metadaten zu teilen:

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

### Häufige Probleme

| Problem | Ursache | Lösung |
|---------|---------|--------|
| "Property type X not found" | Property nicht in FSH definiert | `^property[+].code` hinzufügen |
| "Column not found" | Spaltenname stimmt nicht (case-sensitive) | CSV-Header prüfen oder `--headers` setzen |
| Duplicate codes | Mehrere Zeilen mit gleichem Code | `--no-filter-duplicates` oder CSV bereinigen |
| Falsche Sonderzeichen | Encoding-Problem | `--charset=UTF-8` setzen |
| Leeres CodeSystem | CSV-Struktur nicht parsbar | Wide-Format prüfen, Delimiter prüfen |

### Integration mit CEIR-OS

BabelFSH ergänzt die Terminologie-Werkzeuge von CEIR-OS:

1. **Eigene CodeSystems erstellen** mit BabelFSH aus CSV/Excel
2. **Codes validieren** mit `validate_code` über den [Terminology MCP Server](terminologie-mcp.html)
3. **Mappings erstellen** mit ConceptMaps (siehe [FHIR Mappings](fhir-mappings.html))
4. **Profile testen** mit dem [FHIR Spezifikations-Navigator](fhir-spec-mcp.html)

### Weiterführende Ressourcen

- [BabelFSH Repository](https://gitlab.com/mii-termserv/babelfsh)
- [BabelFSH Dokumentation](https://su-termserv.gitbook.io/babelfsh)
- [CSV Plugin Referenz](https://su-termserv.gitbook.io/babelfsh/plugin-docs/codesystem/csv)
- [FHIR CodeSystem Spezifikation](https://www.hl7.org/fhir/codesystem.html)
- [FSH Spezifikation](https://hl7.org/fhir/uv/shorthand/)
