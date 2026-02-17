Instance: CEIROSSnowstorm
InstanceOf: CapabilityStatement
Usage: #definition
Title: "CEIR-OS Snowstorm SNOMED CT Server"
Description: "CapabilityStatement für den Snowstorm FHIR Terminologieserver innerhalb von CEIR-OS. Stellt SNOMED CT Terminologie-Operationen bereit."
* status = #active
* date = "2024-01-01"
* kind = #instance
* fhirVersion = #4.0.1
* format[+] = #json
* format[+] = #xml
* implementation.description = "Snowstorm SNOMED CT FHIR Terminologieserver"
* implementation.url = "http://localhost:8090/fhir"
* software.name = "Snowstorm"
* software.version = "10.8.2"
* rest[+].mode = #server
* rest[=].documentation = "SNOMED CT Terminologie-Services via FHIR R4 API. Stellt CodeSystem, ValueSet und ConceptMap Operationen bereit."
* rest[=].resource[+].type = #CodeSystem
* rest[=].resource[=].interaction[+].code = #read
* rest[=].resource[=].interaction[+].code = #search-type
* rest[=].resource[=].operation[+].name = "$lookup"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/CodeSystem-lookup"
* rest[=].resource[=].operation[+].name = "$validate-code"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/CodeSystem-validate-code"
* rest[=].resource[=].operation[+].name = "$subsumes"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/CodeSystem-subsumes"
* rest[=].resource[+].type = #ValueSet
* rest[=].resource[=].interaction[+].code = #read
* rest[=].resource[=].interaction[+].code = #search-type
* rest[=].resource[=].operation[+].name = "$expand"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/ValueSet-expand"
* rest[=].resource[=].operation[+].name = "$validate-code"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/ValueSet-validate-code"
* rest[=].resource[+].type = #ConceptMap
* rest[=].resource[=].interaction[+].code = #read
* rest[=].resource[=].interaction[+].code = #search-type
* rest[=].resource[=].operation[+].name = "$translate"
* rest[=].resource[=].operation[=].definition = "http://hl7.org/fhir/OperationDefinition/ConceptMap-translate"
