Instance: CEIROSMCPBridge
InstanceOf: CapabilityStatement
Usage: #definition
Title: "CEIR-OS MCP-OpenAI Bridge"
Description: "CapabilityStatement fuer die MCP-OpenAI Bridge. Uebersetzt MCP-Tools in das OpenAI Function Calling Format fuer lokale LLMs via Ollama."
* status = #active
* date = "2024-01-01"
* kind = #instance
* fhirVersion = #4.0.1
* format[+] = #json
* implementation.description = "MCP-zu-OpenAI Bridge mit Smart Retry, Emoji Parser und Result Trimming"
* implementation.url = "http://localhost:8000"
* software.name = "mcp-openai-bridge"
* software.version = "0.1.0"
* rest[+].mode = #server
* rest[=].documentation = "OpenAI-kompatible API (/v1/chat/completions, /v1/models) die MCP-Tools als Function Calls bereitstellt. Features: dynamische Tool-Discovery, Smart Search Retry, Emoji/XML Tool Call Parser, Result Trimming (max 4000 Zeichen)."
* rest[=].extension[+].url = "https://bih-cei.github.io/ceir-os-ig/StructureDefinition/mcp-tool-definition"
* rest[=].extension[=].extension[+].url = "toolName"
* rest[=].extension[=].extension[=].valueString = "openai_chat_completions"
* rest[=].extension[=].extension[+].url = "toolDescription"
* rest[=].extension[=].extension[=].valueString = "OpenAI-kompatibler Chat-Endpoint mit automatischem Tool-Routing zu MCP-Servern"
* rest[=].extension[=].extension[+].url = "sseEndpoint"
* rest[=].extension[=].extension[=].valueUrl = "http://localhost:8000/v1/chat/completions"
