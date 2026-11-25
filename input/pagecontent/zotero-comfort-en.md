*Deutsche Fassung: [Zotero Literaturverwaltung](zotero-comfort.html)*

Zotero Comfort is an MCP server for literature management in CEIR-OS. It offers dual-library support (group and personal library), PubMed and arXiv integration, and tools for managing publications.

### Overview

| Property | Value |
|------------|------|
| Container | `ceir-zotero-comfort` |
| Port | 3001 |
| Protocol | MCP |
| Libraries | Group (CEI_Publications) + Personal (optional) |

### Dual-library concept

Zotero Comfort supports two libraries at the same time:

| Library | Purpose | Configuration |
|-----------|-------|--------------|
| **Group Library** (CEI_Publications) | Shared team library | `ZOTERO_GROUP_API_KEY`, `ZOTERO_GROUP_LIBRARY_ID` |
| **Personal Library** (optional) | Individual collection | `ZOTERO_PERSONAL_API_KEY`, `ZOTERO_PERSONAL_LIBRARY_ID` |

### Available tools

#### search_papers

Searches the Zotero library for publications.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `query` | string | Search term |
| `library` | string | `group` or `personal` (default: `group`) |

#### get_paper_metadata

Retrieves the metadata of a specific paper (title, authors, abstract, DOI, etc.).

| Parameter | Type | Description |
|-----------|-----|-------------|
| `item_key` | string | Zotero item key |

#### suggest_collection

Suggests a suitable collection for a paper, based on its content and the existing collections.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `item_key` | string | Zotero item key |

#### list_collections

Lists all available collections in the library.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `library` | string | `group` or `personal` (default: `group`) |

#### build_topic_collection

Creates a thematic reading list from existing papers.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `topic` | string | Topic of the reading list |
| `max_items` | integer | Maximum number of papers |

#### tag_ready_for_website

Marks a paper for publication on the website.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `item_key` | string | Zotero item key |

#### export_collection_bibtex

Exports a collection as a BibTeX file.

| Parameter | Type | Description |
|-----------|-----|-------------|
| `collection_key` | string | Zotero collection key |

### PubMed and arXiv integration

Zotero Comfort can search literature directly in PubMed and arXiv and import it into the library. This enables an integrated workflow from literature research to management.

### Configuration

| Environment variable | Default | Description |
|-------------------|---------|-------------|
| `ZOTERO_MCP_PORT` | `3001` | Host port |
| `ZOTERO_GROUP_LIBRARY_ID` | `5767153` | Group library ID |
| `ZOTERO_GROUP_API_KEY` | - | API key for the group library |
| `ZOTERO_PERSONAL_LIBRARY_ID` | - | Personal library ID |
| `ZOTERO_PERSONAL_API_KEY` | - | API key for the personal library |
| `LOG_LEVEL` | `info` | Log level |

### Creating API keys

1. Go to [zotero.org/settings/keys/new](https://www.zotero.org/settings/keys/new)
2. Create a key with read access to the desired library
3. For the group library: make sure the key has access to the group `CEI_Publications`
4. Enter the keys in the `.env` file
