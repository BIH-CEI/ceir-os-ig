Snowstorm ist der SNOMED CT Terminologieserver in CEIR-OS. Er stellt eine vollstaendige FHIR R4-konforme Schnittstelle fuer SNOMED CT bereit.

### Uebersicht

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-snowstorm` |
| Image | `snomedinternational/snowstorm:10.8.2` |
| Port | 8090 (Host) -> 8080 (Container) |
| Datenbank | Elasticsearch 8.11.1 |
| FHIR-Version | R4 |

### FHIR R4 API

Snowstorm stellt folgende FHIR-Operationen bereit:

#### CodeSystem/$lookup

Details fuer einen bekannten SNOMED CT Code abrufen:

```bash
curl -s "http://localhost:8090/fhir/CodeSystem/\$lookup?system=http://snomed.info/sct&code=84114007" | jq .
```

Antwort (gekuerzt):

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

SNOMED CT ValueSets expandieren (z.B. alle Kinder eines Konzepts):

```bash
curl -s "http://localhost:8090/fhir/ValueSet/\$expand?url=http://snomed.info/sct?fhir_vs=ecl/<< 84114007&count=10" | jq .
```

#### ConceptMap/$translate

Code-Uebersetzungen zwischen Terminologien:

```bash
curl -s "http://localhost:8090/fhir/ConceptMap/\$translate?system=http://snomed.info/sct&code=84114007&targetSystem=http://hl7.org/fhir/sid/icd-10" | jq .
```

### Expression Constraint Language (ECL)

Snowstorm unterstuetzt die SNOMED CT Expression Constraint Language fuer komplexe Abfragen:

| ECL-Ausdruck | Bedeutung |
|-------------|-----------|
| `<< 84114007` | Herzinsuffizienz und alle Untertypen |
| `< 84114007` | Nur Untertypen (ohne Herzinsuffizienz selbst) |
| `>> 84114007` | Herzinsuffizienz und alle Obertypen |
| `^ 816080008` | Mitglieder des International Patient Summary RefSets |
| `< 404684003 : 363698007 = 39057004` | Klinische Befunde mit Finding Site = Lungenstruktur |

Beispiel: Alle Diabetes-Untertypen finden:

```bash
curl -s "http://localhost:8090/fhir/ValueSet/\$expand?url=http://snomed.info/sct?fhir_vs=ecl/<< 73211009&count=20" | jq '.expansion.contains[] | {code, display}'
```

### SNOMED CT Browser

Der SNOMED CT Browser bietet eine grafische Oberflaeche zur Exploration der Terminologie:

| Eigenschaft | Wert |
|------------|------|
| Container | `ceir-browser` |
| Port | 4000 |
| Image | `snomedinternational/snomedct-browser:latest` |

Oeffnen Sie `http://localhost:4000` im Browser, um SNOMED CT Konzepte zu suchen, Hierarchien zu navigieren und Beziehungen zu erkunden.

### SNOMED CT Import

Der Import erfolgt beim ersten Start automatisch ueber zwei Init-Container:

1. **snomed-unpacker**: Entpackt das SNOMED-Paket (ZIP) in das `sct_files`-Volume
2. **snomed-importer**: Laedt die RF2-Dateien ueber die Snowstorm REST API

Der Importvorgang kann je nach Paketgroesse 10-30 Minuten dauern. Der Fortschritt kann ueber die Logs verfolgt werden:

```bash
# Unpacker-Fortschritt
docker logs ceir-snomed-unpacker

# Importer-Fortschritt
docker logs -f ceir-snomed-importer
```

Nach erfolgreichem Import wird eine Marker-Datei (`.unpacked`) im Volume angelegt. Bei einem Neustart wird der Import uebersprungen.

### REST API Beispiele

**Suche nach Konzepten:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts?term=heart+failure&limit=5" | jq '.items[] | {conceptId, fsn: .fsn.term}'
```

**Konzept-Details abrufen:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts/84114007" | jq '{conceptId, fsn: .fsn.term, definitionStatus}'
```

**Beschreibungen eines Konzepts:**

```bash
curl -s "http://localhost:8090/browser/MAIN/concepts/84114007/descriptions" | jq '.[].term'
```

### Konfiguration

| Umgebungsvariable | Standard | Beschreibung |
|-------------------|---------|-------------|
| `SNOWSTORM_PORT` | `8090` | Host-Port fuer Snowstorm |
| `ES_JAVA_OPTS` | `-Xms1g -Xmx1g` | Elasticsearch-Speicher |

Snowstorm ist im Schreibmodus konfiguriert (`snowstorm.rest.api.readonly=false`), um den initialen Import zu ermoeglichen. Fuer Produktionsumgebungen sollte der Lesemodus aktiviert werden.
