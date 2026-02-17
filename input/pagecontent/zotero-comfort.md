Zotero Comfort ist ein MCP-Server fuer die Literaturverwaltung in CEIR-OS. Er bietet Dual-Library-Unterstuetzung (Gruppen- und persoenliche Bibliothek), PubMed- und arXiv-Integration sowie Tools fuer die Publikationsverwaltung.

### Uebersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-zotero-comfort` |
| Port | 3001 |
| Protokoll | MCP |
| Bibliotheken | Group (CEI_Publications) + Personal (optional) |

### Dual-Library-Konzept

Zotero Comfort unterstuetzt zwei Bibliotheken gleichzeitig:

| Bibliothek | Zweck | Konfiguration |
|-----------|-------|--------------|
| **Group Library** (CEI_Publications) | Geteilte Team-Bibliothek | `ZOTERO_GROUP_API_KEY`, `ZOTERO_GROUP_LIBRARY_ID` |
| **Personal Library** (optional) | Individuelle Sammlung | `ZOTERO_PERSONAL_API_KEY`, `ZOTERO_PERSONAL_LIBRARY_ID` |

### Verfuegbare Tools

#### search_papers

Durchsucht die Zotero-Bibliothek nach Publikationen.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `query` | string | Suchbegriff |
| `library` | string | `group` oder `personal` (Standard: `group`) |

#### get_paper_metadata

Ruft die Metadaten eines bestimmten Papers ab (Titel, Autoren, Abstract, DOI, etc.).

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `item_key` | string | Zotero Item Key |

#### suggest_collection

Schlaegt eine passende Sammlung (Collection) fuer ein Paper vor, basierend auf Inhalt und vorhandenen Sammlungen.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `item_key` | string | Zotero Item Key |

#### list_collections

Listet alle verfuegbaren Sammlungen in der Bibliothek auf.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `library` | string | `group` oder `personal` (Standard: `group`) |

#### build_topic_collection

Erstellt eine thematische Leseliste aus vorhandenen Papers.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `topic` | string | Thema der Leseliste |
| `max_items` | integer | Maximale Anzahl Papers |

#### tag_ready_for_website

Markiert ein Paper fuer die Veroeffentlichung auf der Website.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `item_key` | string | Zotero Item Key |

#### export_collection_bibtex

Exportiert eine Sammlung als BibTeX-Datei.

| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `collection_key` | string | Zotero Collection Key |

### PubMed und arXiv Integration

Zotero Comfort kann Literatur direkt aus PubMed und arXiv suchen und in die Bibliothek importieren. Dies ermoeglicht einen integrierten Workflow von der Literaturrecherche bis zur Verwaltung.

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `ZOTERO_MCP_PORT` | `3001` | Host-Port |
| `ZOTERO_GROUP_LIBRARY_ID` | `5767153` | Gruppen-Bibliothek ID |
| `ZOTERO_GROUP_API_KEY` | - | API-Key fuer Gruppen-Bibliothek |
| `ZOTERO_PERSONAL_LIBRARY_ID` | - | Persoenliche Bibliothek ID |
| `ZOTERO_PERSONAL_API_KEY` | - | API-Key fuer persoenliche Bibliothek |
| `LOG_LEVEL` | `info` | Log-Level |

### API-Keys erstellen

1. Gehen Sie zu [zotero.org/settings/keys/new](https://www.zotero.org/settings/keys/new)
2. Erstellen Sie einen Key mit Lesezugriff auf die gewuenschte Bibliothek
3. Fuer die Gruppen-Bibliothek: Stellen Sie sicher, dass der Key Zugriff auf die Gruppe `CEI_Publications` hat
4. Tragen Sie die Keys in die `.env`-Datei ein
