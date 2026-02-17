CEIR-OS unterstuetzt FHIR-Mapping-Workflows fuer die Transformation und Zuordnung medizinischer Daten. Diese Seite beschreibt die verfuegbaren Methoden und deren Integration mit den Terminologie-Tools.

### Uebersicht der Mapping-Methoden

| Methode | Artefakt | Zweck |
|---------|---------|-------|
| ConceptMap (FSH) | FHIR ConceptMap | Terminologie-Zuordnungen (Code-zu-Code) |
| StructureMap (FML) | FHIR StructureMap | Strukturelle Transformationen (Ressource-zu-Ressource) |
| MapQual | Qualitaetsberichte | Bewertung der Mapping-Qualitaet |

### ConceptMap fuer Terminologie-Mappings

Eine ConceptMap definiert Zuordnungen zwischen Codes verschiedener Terminologien. In CEIR-OS werden ConceptMaps in FSH (FHIR Shorthand) geschrieben.

#### Beispiel: ICD-10-GM zu SNOMED CT

```fsh
Instance: ICD10GM-to-SNOMED-Diabetes
InstanceOf: ConceptMap
Title: "ICD-10-GM zu SNOMED CT Mapping (Diabetes)"
Usage: #definition

* status = #draft
* sourceUri = "http://fhir.de/CodeSystem/bfarm/icd-10-gm"
* targetUri = "http://snomed.info/sct"

* group[+]
  * source = "http://fhir.de/CodeSystem/bfarm/icd-10-gm"
  * target = "http://snomed.info/sct"

  * element[+]
    * code = #E10.9
    * display = "Diabetes mellitus, Typ 1, ohne Komplikationen"
    * target[+]
      * code = #46635009
      * display = "Type 1 diabetes mellitus"
      * equivalence = #wider

  * element[+]
    * code = #E11.9
    * display = "Diabetes mellitus, Typ 2, ohne Komplikationen"
    * target[+]
      * code = #44054006
      * display = "Type 2 diabetes mellitus"
      * equivalence = #wider
```

#### Equivalence-Typen

| Wert | Bedeutung |
|------|-----------|
| `#equivalent` | Semantisch identisch |
| `#wider` | Ziel ist breiter als Quelle |
| `#narrower` | Ziel ist enger als Quelle |
| `#inexact` | Ungefaehre Entsprechung |
| `#unmatched` | Keine Entsprechung |

### StructureMap fuer strukturelle Transformationen

StructureMaps definieren Transformationen zwischen FHIR-Ressourcen. Sie werden in FHIR Mapping Language (FML) geschrieben.

#### Beispiel: Condition zu Observation

```fml
map "http://example.org/StructureMap/ConditionToObservation" = "ConditionToObservation"

uses "http://hl7.org/fhir/StructureDefinition/Condition" as source
uses "http://hl7.org/fhir/StructureDefinition/Observation" as target

group main(source src: Condition, target tgt: Observation) {
  src.code -> tgt.code;
  src.subject -> tgt.subject;
  src.recordedDate -> tgt.effectiveDateTime;
  src -> tgt.status = 'final';
}
```

### MapQual: Mapping-Qualitaetssicherung

MapQual ist ein Ansatz zur systematischen Bewertung der Qualitaet von Terminologie-Mappings. Qualitaetskriterien umfassen:

| Kriterium | Beschreibung |
|-----------|-------------|
| Vollstaendigkeit | Anteil der Quell-Codes mit Mapping |
| Korrektheit | Stimmt die semantische Zuordnung? |
| Granularitaet | Passt der Detailgrad (wider/narrower)? |
| Konsistenz | Einheitliche Anwendung der Equivalence-Typen |
| Aktualitaet | Basiert das Mapping auf aktuellen Versionen? |

### Integration mit Terminologie-Tools

Die Terminologie-Tools von CEIR-OS unterstuetzen den Mapping-Workflow:

| Schritt | Tool | Beschreibung |
|---------|------|-------------|
| Quell-Code identifizieren | `search_across_versions` | ICD-10-GM/OPS/ATC Code finden |
| Ziel-Code finden | `lookup_code` | SNOMED CT Kandidat nachschlagen |
| Code validieren | `validate_code` | Existenz im Zielsystem pruefen |
| LOINC-Zuordnung | `search_common_loinc` | Passenden LOINC-Code finden |
| Deutsche Labels | `get_german_label` | Uebersetzung fuer Dokumentation |
| FHIR-Struktur | FHIR Spec MCP | Ziel-Ressource definieren |

#### Workflow-Beispiel: ICD-10-GM zu SNOMED CT

1. **Quell-Code suchen**: `search_across_versions` mit System `http://fhir.de/CodeSystem/bfarm/icd-10-gm` und Suchtext "Diabetes"
2. **SNOMED-Kandidaten finden**: `lookup_code` mit System `http://snomed.info/sct` fuer verwandte Konzepte
3. **Mapping validieren**: `validate_code` um sicherzustellen, dass der SNOMED-Code existiert
4. **ConceptMap erstellen**: FSH-Definition mit den gefundenen Codes
5. **Qualitaet pruefen**: Equivalence-Typ und Vollstaendigkeit bewerten

### FHIR-Mapping-Ressourcen im Implementation Guide

Dieser Implementation Guide kann ConceptMap- und StructureMap-Instanzen enthalten. Sie werden als FSH-Dateien im Verzeichnis `input/fsh/` definiert und beim Build in FHIR JSON konvertiert.
