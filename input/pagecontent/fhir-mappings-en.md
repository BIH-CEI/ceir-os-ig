*Deutsche Fassung: [FHIR Mappings](fhir-mappings.html)*

CEIR-OS supports FHIR mapping workflows for transforming and mapping medical data. This page describes the available methods and their integration with the terminology tools.

### Overview of the Mapping Methods

| Method | Artifact | Purpose |
|---------|---------|-------|
| ConceptMap (FSH) | FHIR ConceptMap | Terminology mappings (code to code) |
| StructureMap (FML) | FHIR StructureMap | Structural transformations (resource to resource) |
| MapQual | Quality reports | Assessment of mapping quality |

### ConceptMap for Terminology Mappings

A ConceptMap defines mappings between codes of different terminologies. In CEIR-OS, ConceptMaps are written in FSH (FHIR Shorthand).

#### Example: ICD-10-GM to SNOMED CT

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

#### Equivalence Types

| Value | Meaning |
|------|-----------|
| `#equivalent` | Semantically identical |
| `#wider` | Target is broader than source |
| `#narrower` | Target is narrower than source |
| `#inexact` | Approximate correspondence |
| `#unmatched` | No correspondence |

### StructureMap for Structural Transformations

StructureMaps define transformations between FHIR resources. They are written in the FHIR Mapping Language (FML).

#### Example: Condition to Observation

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

### MapQual: Mapping Quality Assurance

MapQual is an approach for systematically assessing the quality of terminology mappings. Quality criteria include:

| Criterion | Description |
|-----------|-------------|
| Completeness | Share of source codes with a mapping |
| Correctness | Is the semantic mapping right? |
| Granularity | Does the level of detail fit (wider/narrower)? |
| Consistency | Uniform application of the equivalence types |
| Currency | Is the mapping based on current versions? |

### Integration with Terminology Tools

The terminology tools of CEIR-OS support the mapping workflow:

| Step | Tool | Description |
|---------|------|-------------|
| Identify source code | `search_across_versions` | Find ICD-10-GM/OPS/ATC code |
| Find target code | `lookup_code` | Look up SNOMED CT candidate |
| Validate code | `validate_code` | Check existence in the target system |
| LOINC mapping | `search_common_loinc` | Find a matching LOINC code |
| German labels | `get_german_label` | Translation for documentation |
| FHIR structure | FHIR Spec MCP | Define target resource |

#### Workflow Example: ICD-10-GM to SNOMED CT

1. **Search source code**: `search_across_versions` with system `http://fhir.de/CodeSystem/bfarm/icd-10-gm` and search text "Diabetes"
2. **Find SNOMED candidates**: `lookup_code` with system `http://snomed.info/sct` for related concepts
3. **Validate mapping**: `validate_code` to make sure the SNOMED code exists
4. **Create ConceptMap**: FSH definition with the codes found
5. **Check quality**: assess equivalence type and completeness

### FHIR Mapping Resources in the Implementation Guide

This Implementation Guide can contain ConceptMap and StructureMap instances. They are defined as FSH files in the `input/fsh/` directory and converted to FHIR JSON during the build.
