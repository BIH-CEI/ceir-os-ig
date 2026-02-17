Instance: CEIROSFhirSpecMCP
InstanceOf: CapabilityStatement
Usage: #definition
Title: "CEIR-OS FHIR Spec MCP Server"
Description: "CapabilityStatement für den FHIR Spezifikations-Navigator. Ermöglicht das Durchsuchen und Navigieren der FHIR R4 Spezifikation über MCP."
* status = #active
* date = "2024-01-01"
* kind = #instance
* fhirVersion = #4.0.1
* format[+] = #json
* implementation.description = "FHIR R4 Spezifikations-Navigator via MCP"
* implementation.url = "http://localhost:8002"
* software.name = "fhir-spec-mcp"
* software.version = "1.0.0"
* rest[+].mode = #server
* rest[=].documentation = "Stellt FHIR R4 Spezifikationsdaten ueber MCP SSE bereit. Ermoeglicht Ressourcen-Definitionen, Suchparameter und Profile zu durchsuchen."
* rest[=].extension[+].url = "https://bih-cei.github.io/ceir-os-ig/StructureDefinition/mcp-tool-definition"
* rest[=].extension[=].extension[+].url = "toolName"
* rest[=].extension[=].extension[=].valueString = "get_resource_definition"
* rest[=].extension[=].extension[+].url = "toolDescription"
* rest[=].extension[=].extension[=].valueString = "FHIR R4 Ressourcen-Definition abrufen (Elemente, Kardinalitaeten, Datentypen)"
* rest[=].extension[=].extension[+].url = "sseEndpoint"
* rest[=].extension[=].extension[=].valueUrl = "http://localhost:8002/sse"
* rest[=].extension[+].url = "https://bih-cei.github.io/ceir-os-ig/StructureDefinition/mcp-tool-definition"
* rest[=].extension[=].extension[+].url = "toolName"
* rest[=].extension[=].extension[=].valueString = "search_fhir_spec"
* rest[=].extension[=].extension[+].url = "toolDescription"
* rest[=].extension[=].extension[=].valueString = "FHIR R4 Spezifikation durchsuchen (Ressourcen, Datentypen, Suchparameter)"
* rest[=].extension[=].extension[+].url = "sseEndpoint"
* rest[=].extension[=].extension[=].valueUrl = "http://localhost:8002/sse"
