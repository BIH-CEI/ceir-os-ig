*Deutsche Fassung: [FHIR Spezifikations-Navigator](fhir-spec-mcp.html)*

The FHIR Specification Navigator provides MCP-based access to the FHIR R4 specification (v4.0.1). It is used to look up resource definitions, check cardinalities and explore FHIR data types.

### Overview

| Property | Value |
|------------|------|
| Container | `ceir-fhir-spec-mcp` |
| Port | 8002 |
| Image | `ghcr.io/bih-cei/fhir-spec-mcp:latest` |
| FHIR version | 4.0.1 (R4) |
| Protocol | MCP (SSE) |
| Repository | [github.com/BIH-CEI/fhir-spec-mcp](https://github.com/BIH-CEI/fhir-spec-mcp) |

### How it works

The server uses the FHIR R4 package (`hl7.fhir.r4.core#4.0.1`) from the local FHIR package cache (`~/.fhir/packages`). This cache is filled automatically when SUSHI or the FHIR Terminal has been used locally. The volume `fhir-packages` mounts this cache into the container.

The data is stored in two persistent volumes:
- `fhir-packages`: FHIR package cache (from `~/.fhir/packages`)
- `fhir-cache`: Parsed specification data for fast access

> **Prerequisite:** `sushi` or the FHIR Terminal must have run at least once on the host so that `hl7.fhir.r4.core#4.0.1` is in the package cache.

Queries can be made both via Claude Code and via the MCP Bridge (and thus OpenWebUI).

### Available tools

#### list_resources

Lists available FHIR resources, data types or extensions.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `kind` | string | Kind of resources (`resource`, `datatype`, `extension`) |

#### get_elements

Returns all elements of a resource with cardinality, types and descriptions.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource (e.g. `Patient`, `Observation`) |
| `include_inherited` | boolean | Include inherited elements |

#### get_required_elements

Returns only the mandatory elements (min>=1) of a resource.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |

#### get_references

Returns elements that reference other resources.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |

#### get_bindings

Returns elements with terminology bindings (ValueSets).

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |

#### get_element_detail

Returns detailed information on a specific element.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |
| `element_path` | string | Path of the element (e.g. `Observation.value[x]`) |

#### get_resource_metadata

Returns metadata of a resource (scope, maturity, standards status).

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |

#### get_documentation

Retrieves the narrative documentation of a resource from hl7.org.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |
| `max_length` | integer | Maximum length of the documentation |

#### search_documentation

Searches the documentation of a resource for specific terms.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource` | string | Name of the FHIR resource |
| `query` | string | Search term |

#### compare_resources

Compares the elements of two resources.

**Parameters:**

| Parameter | Type | Description |
|-----------|-----|-------------|
| `resource1` | string | Name of the first FHIR resource |
| `resource2` | string | Name of the second FHIR resource |

### Use cases

- **Look up resource definitions**: Which elements does an Observation have? Which ones are mandatory?
- **Check cardinalities**: Is `Observation.value[x]` mandatory (1..1) or optional (0..1)?
- **Explore data types**: Which choices exist for `value[x]` (valueQuantity, valueCodeableConcept, etc.)?
- **Profile development**: Which elements can be constrained in a profile?
- **Mapping support**: Which FHIR elements fit a given clinical concept?

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `FHIR_SPEC_MCP_PORT` | `8002` | Host port |
| `FHIR_SPEC_VERSION` | `4.0.1` | FHIR version |
| `LOG_LEVEL` | `info` | Log level |

### Health Check

```bash
curl -s http://localhost:8002/health
```
