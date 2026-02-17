# CEIR-OS Implementation Guide

Bedienungsanleitung für **CEIR-OS** – Claude-Enabled Interoperability Research Operating Stack.

Publiziert unter: https://bih-cei.github.io/ceir-os-ig/

## Lokaler Build

### Voraussetzungen
- [Node.js](https://nodejs.org/) >= 18
- [SUSHI](https://fshschool.org/docs/sushi/installation/) (`npm install -g fsh-sushi`)
- [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases) (optional, für vollständigen Build)

### SUSHI Build
```bash
sushi .
```

### Vollständiger IG Build
```bash
./_updatePublisher.sh   # einmalig
./_genonce.sh -tx n/a   # Build ohne externen Terminology-Server
```

## Struktur

```
input/
├── fsh/                    # FHIR Shorthand Definitionen
│   ├── aliases.fsh
│   ├── capabilitystatements/
│   └── extensions/
├── pagecontent/            # Narrative Seiten (Deutsch)
└── images/                 # Bilder und Logo
```

## Lizenz

CC BY 4.0 – Berlin Institute of Health at Charité
