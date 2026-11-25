*Deutsche Fassung: [Snowstorm SNOMED CT](snowstorm.html)*

Snowstorm is the SNOMED CT terminology server in CEIR-OS. It provides a complete FHIR R4-compliant interface for SNOMED CT.

### Overview

| Property | Value |
|------------|------|
| Container | `ceir-snowstorm` |
| Image | `snomedinternational/snowstorm:10.8.2` |
| Port | 8090 (host) -> 8080 (container) |
| Database | Elasticsearch 8.11.1 |
| FHIR version | R4 |

### FHIR R4 API

Snowstorm provides the following FHIR operations:

#### CodeSystem/$lookup

Retrieve details for a known SNOMED CT code:

```bash
curl -s "http://localhost:8090/fhir/CodeSystem/\$lookup?system=http://snomed.info/sct&code=84114007" | jq .
```

Response (abridged):

```json
{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "name", "valueString": "SNOMED CT" },
    { "name": "display", "valueString": "Heart failure" },
    { "name": "property", "part": [
      { "name": "code", "valueCode": "parent" },
      { "name": "value", "valueCode": "84114007" }
    ]}
  ]
}
```

#### ValueSet/$expand

Expand SNOMED CT value sets (e.g. all children of a concept):

```bash
curl -s "http://localhost:8090/fhir/ValueSet/\$expand?url=http://snomed.info/sct?fhir_vs=ecl/<< 84114007&count=10" | jq .
```

#### ConceptMap/$translate

Code translations between terminologies:

```bash
curl -s "http://localhost:8090/fhir/ConceptMap/\$translate?system=http://snomed.info/sct&code=84114007&targetSystem=http://hl7.org/fhir/sid/icd-10" | jq .
```

### Expression Constraint Language (ECL)

Snowstorm supports the SNOMED CT Expression Constraint Language for complex queries:

| ECL expression | Meaning |
|-------------|-----------|
| `<< 84114007` | Heart failure and all its subtypes |
| `< 84114007` | Subtypes only (without heart failure itself) |
| `>> 84114007` | Heart failure and all its supertypes |
| `^ 816080008` | Members of the International Patient Summary RefSet |
| `< 404684003 : 363698007 = 39057004` | Clinical findings with Finding Site = lung structure |

Example: find all diabetes subtypes:

```bash
curl -s "http://localhost:8090/fhir/ValueSet/\$expand?url=http://snomed.info/sct?fhir_vs=ecl/<< 73211009&count=20" | jq '.expansion.contains[] | {code, display}'
```

### SNOMED CT Browser

The SNOMED CT Browser offers a graphical interface for exploring the terminology:

| Property | Value |
|------------|------|
| Container | `ceir-browser` |
| Port | 4000 |
| Image | `snomedinternational/snomedct-browser:latest` |

Open `http://localhost:4000` in your browser to search SNOMED CT concepts, navigate hierarchies and explore relationships.

### SNOMED CT data

The SNOMED CT ZIP file is provided within the team and mounted directly into the container as a volume.

**Local:** The ZIP file is referenced via `SNOMED_PACKAGE_PATH` in `.env`. On first startup, the `snomed-unpacker` container automatically unpacks the file into the `sct_files` volume.

**CI/CD:** In pipelines, the ZIP file can be provided as a build artifact or via a prepared volume mount.

### Import process

On first startup, the import runs automatically via two init containers:

1. **snomed-unpacker**: Unpacks the mounted ZIP into the `sct_files` volume
2. **snomed-importer**: Loads the RF2 files via the Snowstorm REST API

Depending on the package size, the import can take 10-30 minutes:

```bash
# Unpacker progress
docker logs ceir-snomed-unpacker

# Importer progress
docker logs -f ceir-snomed-importer
```

After a successful import, a marker file (`.unpacked`) is created in the volume. On a restart, the import is skipped.

### REST API examples

**Search for concepts:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts?term=heart+failure&limit=5" | jq '.items[] | {conceptId, fsn: .fsn.term}'
```

**Retrieve concept details:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts/84114007" | jq '{conceptId, fsn: .fsn.term, definitionStatus}'
```

**Descriptions of a concept:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts/84114007/descriptions" | jq '.[].term'
```

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `SNOWSTORM_PORT` | `8090` | Host port for Snowstorm |
| `ES_JAVA_OPTS` | `-Xms1g -Xmx1g` | Elasticsearch memory |

Snowstorm is configured in write mode (`snowstorm.rest.api.readonly=false`) to allow the initial import. For production environments, read-only mode should be enabled.
