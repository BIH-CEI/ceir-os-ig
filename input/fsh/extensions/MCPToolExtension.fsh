Extension: MCPToolDefinition
Id: mcp-tool-definition
Title: "MCP Tool Definition"
Description: "Beschreibt ein MCP-Tool (Model Context Protocol) als Extension auf CapabilityStatement.rest. Da MCP-Tools keine Standard-FHIR-Operationen sind, werden sie über diese Extension formal beschrieben."
Context: CapabilityStatement.rest
* extension contains
    toolName 1..1 MS and
    toolDescription 0..1 and
    sseEndpoint 0..1 and
    inputSchema 0..1
* extension[toolName].value[x] only string
* extension[toolName] ^short = "Name des MCP-Tools"
* extension[toolDescription].value[x] only string
* extension[toolDescription] ^short = "Beschreibung der Tool-Funktionalität"
* extension[sseEndpoint].value[x] only url
* extension[sseEndpoint] ^short = "SSE-Endpoint URL für MCP-Kommunikation"
* extension[inputSchema].value[x] only string
* extension[inputSchema] ^short = "JSON Schema der Tool-Parameter (als String)"
