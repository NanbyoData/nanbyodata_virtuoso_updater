# nanbyodata_virtuoso_updater

## Overview

* This repository is required for updating the Virtuoso data used in the NanbyoData.
* For the NanbyoData MySQL update tool, please refer to [this link](https://github.com/NanbyoData/nanbyodata_updater/).

## Prerequisites

* **Docker** / **Docker Compose**

## Setup & Usage

### 1. Environment Configuration

Initialize your environment variables by copying the template file and editing it with your local settings.

```bash
cp template.env .env
vi .env
```

### 2. Building Containers  
Build the required Docker images for each environment. Note that the MySQL build requires local user IDs for volume permission consistency.

```bash
docker compose build virtuoso
```

### 3. Execution

Start the container with the following command:  

```bash
docker compose up -d
```

---

## Operations

Pass the data root directory (the parent of `ontology`) with `-o`.
Edit `config/data_sources.csv`, prepare directories, then install data into `latest`:

```bash
vi config/data_sources.csv
bash scripts/create_data_dirs.sh -o /path/to/nanbyodata -c config/data_sources.csv -a
bash scripts/get_data.sh -o /path/to/nanbyodata -c config/data_sources.csv -a
# Select individual datasets, or use another config file:
bash scripts/get_data.sh -o /path/to/nanbyodata -c config/data_sources.csv hp mondo medgen mp
bash scripts/create_data_dirs.sh -o /path/to/nanbyodata -c /path/to/data_sources.csv -a
bash scripts/get_data.sh -o /path/to/nanbyodata -c /path/to/data_sources.csv -a
```

Both commands require the config path via `-c`; there is no default path.
Relative config paths resolve from the working directory. The CSV has only
three columns: data name, acquisition method, and source URL.

```csv
name,method,source
hp,download,http://purl.obolibrary.org/obo/hp.owl
nando,manual,-
pcf,manual,-
```

Use `-` for unused or not-yet-configured sources. Directory preparation logs missing
download URLs; installation requires a URL for each selected download dataset.
Use three comma-separated values without quotes; commas and double
quotes inside values are not supported. Blank lines
are ignored; LF and CRLF line endings are accepted.
Save the file as UTF-8. The supported dataset names, destination directories, and
filenames are defined in `scripts/data_config.sh`:

| Data | Directory relative to data root | Filename |
| --- | --- | --- |
| `hp` | `ontology/hp` | `hp.owl` |
| `mondo` | `ontology/mondo` | `mondo-international.owl` |
| `mp` | `mp` | `mp-international.owl` |
| `medgen` | `medgen_rdf` | Names from the downloaded files |
| `nando` | `ontology/nando` | `nando.ttl` |
| `ordo` | `ontology/ordo` | `ordo.owl` |
| `pcf` | `pcf_rdf` | Names from the generation process |
| `rdf` | `rdf` | Names from the source files |

All destinations are under the directory's `latest` symlink.

| Method | Behavior |
| --- | --- |
| `download` | Download a URL to the filename defined in code. |
| `downloadAndParase` | Download `*.ttl.gz` files from a URL and decompress into `latest`. |
| `manual` | Log the placement destination and preserve existing data. |

MedGen uses `downloadAndParase`: it downloads `*.ttl.gz` files and decompresses
these into `latest`. Download or decompression failures stop installation before
processing the next dataset.

ORDO uses `download`, with the English ORDO 4.9 OWL URL from the
[official distribution page](https://sciences.orphadata.com/ordo/) specified in the CSV:

```csv
ordo,download,https://www.orphadata.com/data/ontologies/ordo/last_version/ORDO_en_4.9.owl
```

Update this URL in the config when changing the ORDO version.

PCF, NANDO, and NanbyoData RDF use `manual`. Place or generate PCF data directly
in `pcf_rdf/latest`; `get_data.sh` only displays its destination and preserves it.
The former `-i` and `-p` options are replaced by config settings.

`create_data_dirs.sh` creates `YYYYMMDD` directories, updates each `latest`
symlink, and copies the previous `latest` data into the new directory. Use data
names instead of `-a` to prepare selected datasets. Repeating preparation on the
same day preserves installed data. On the first run, empty directories are created.
After preparation, the command logs config entries requiring manual placement
or a download URL. These notices also appear on
same-day reruns. `get_data.sh` requires prepared `latest` symlinks and does not
create directories or change symlinks. Use the same config for both commands.

Load prepared data into Virtuoso with the same config:

```bash
bash scripts/update_ontology_data.sh -o /rdf_data -c /path/to/data_sources.csv -a
# Load selected datasets:
bash scripts/update_ontology_data.sh -o /rdf_data -c /path/to/data_sources.csv hp mondo
```

Run this command in the Virtuoso container, using paths visible inside it.
Both `-o` and `-c` are required. `-a` loads every dataset registered in the config,
including `manual` datasets after their files have been placed. The loader reads
`latest` directories using the shared directory definitions. Graph names and file
patterns are defined in `update_ontology_data.sh`; `rdf` loads into
`https://nanbyodata.jp/rdf/nanbyodata`. All selected datasets must have matching
files before any graph is cleared. Load errors stop subsequent processing.

Run the local script tests without network access:

```bash
python3 -m unittest discover -s tests
```

The procedure for updating Virtuoso data is as follows:  
* https://docs.google.com/spreadsheets/d/12JjDHkd4k9oI5Xme_Isyg9nqUsHU1PZvmvz5DQPKNZc/edit?gid=1150718828#gid=1150718828  

[!IMPORTANT]  
If you are unable to access the documentation links above, please contact the DBCLS team.  
