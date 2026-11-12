# nanbyodata_virtuoso_updater

## Overview

* This repository is required for updating the Virtuoso data used in the NanbyoData.
* For the NanbyoData MySQL update tool, please refer to [this link](https://github.com/NanbyoData/nanbyodata_updater/).

## Prerequisites

* **Docker** / **Docker Compose**

## Setup & Usage

### 1. Environment Configuration

Create `.env` from `template.env` using your editor and fill in your local settings.
To use this repository's scripts and sample data, set these paths in `.env`:

```dotenv
RDF_DIR=./data/nanbyodata
SCRIPTS_DIR=./scripts
```

The Compose service mounts the data directory at `/rdf_data`, scripts at `/scripts`,
and this repository's `config` directory read-only at `/config`.
Edit `config/data_sources.csv` with your editor before running data operations.

### 2. Execution

Start the container with the following command:  

```bash
docker compose up -d virtuoso-update
```

---

## Operations

Run all scripts inside the `virtuoso-update` container via Docker Compose.
The examples below are issued from the repository directory on the host; the script
paths and arguments refer to paths inside the container. Pass the data root directory
(the parent of `ontologies`) with `-o`.
Run the following four steps in order:

```bash
# 1. Create dated directories and update latest for automatic datasets.
docker compose exec virtuoso-update bash /scripts/create_data_dirs.sh -o /rdf_data -c /config/data_sources.csv -a

# 2. Download data into latest.
docker compose exec virtuoso-update bash /scripts/get_data.sh -o /rdf_data -c /config/data_sources.csv -a

# 3. Load prepared data into Virtuoso.
docker compose exec virtuoso-update bash /scripts/load_data.sh -o /rdf_data -c /config/data_sources.csv -a

# 4. Check the loaded graph counts.
docker compose exec virtuoso-update bash /scripts/check_virtuoso_data.sh
```

The first three commands require `-o` and `-c`; there is no default config path.
In all three scripts, `-a` excludes `nando`, `pcf`, and `rdf`. These datasets
are processed only when explicitly selected by name (`pcf` refers to `pcf_rdf`).
Explicit names can also be combined with `-a`: `-a nando pcf rdf` includes
these three datasets alongside the automatic datasets.
To process selected datasets, replace `-a` with their names (for example, `hp mondo`)
in each of those three commands. Use the same config and selected datasets throughout.
To use another config, place it in the host's `config` directory and specify its
container path under `/config`. The CSV has only
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
| `hp` | `ontologies/hp` | `hp.owl` |
| `mondo` | `ontologies/mondo` | `mondo-international.owl` |
| `mp` | `mp` | `mp-international.owl` |
| `medgen` | `medgen_rdf` | Names from the downloaded files |
| `nando` | `ontologies/nando` | `nando.ttl` |
| `ordo` | `ontologies/ordo` | `ordo.owl` |
| `pcf` | `pcf_rdf` | Names from the generation process |
| `rdf` | `rdf` | Names from the source files |

All destinations are under the directory's `latest` symlink.

| Method | Behavior |
| --- | --- |
| `download` | Download a URL to the filename defined in code. |
| `downloadAndParase` | Download `*.ttl.gz` files from a URL and decompress into `latest`. |
| `manual` | Log the placement destination and preserve existing data. |

MedGen uses `downloadAndParase`: it downloads `*.ttl.gz` files and decompresses
these directly into `latest`. Download or decompression failures stop installation
before processing the next dataset. `manual` datasets are left untouched.

ORDO uses `download`, with the English ORDO 4.9 OWL URL from the
[official distribution page](https://sciences.orphadata.com/ordo/) specified in the CSV:

```csv
ordo,download,https://www.orphadata.com/data/ontologies/ordo/last_version/ORDO_en_4.9.owl
```

Update this URL in the config when changing the ORDO version.

PCF, NANDO, and NanbyoData RDF use `manual`. Place or generate PCF data directly
in `pcf_rdf/latest`; `get_data.sh` only displays its destination and preserves it.
The former `-i` and `-p` options are replaced by config settings.

`create_data_dirs.sh` creates `YYYYMMDD` directories and updates each `latest`
symlink. Only `manual` datasets are copied from the previous `latest`, preserving
file modification times and other attributes with `cp -a`. The destination directory
name uses today's date. Automatically downloaded datasets start empty so that old
filenames are not carried over; `get_data.sh` downloads directly into `latest`. Use data
names instead of `-a` to prepare selected datasets. Repeating preparation on the
same day preserves installed data. On the first run, empty directories are created.
After preparation, the command logs config entries requiring manual placement
or a download URL. These notices also appear on
same-day reruns. `get_data.sh` requires prepared `latest` symlinks and does not
create directories or change symlinks.

`load_data.sh -a` loads the datasets registered in the config except `nando`,
`pcf`, and `rdf`. To load these datasets after preparing their files, specify
their names explicitly instead of `-a`. The loader reads
`latest` directories using the shared directory definitions. Graph names and file
patterns are defined in `load_data.sh`; `rdf` loads into
`https://nanbyodata.jp/rdf/nanbyodata`. All selected datasets must have matching
files before any graph is cleared. Load errors stop subsequent processing.

`check_virtuoso_data.sh` displays the triple count for each graph after loading.

Run the script tests in a disposable Python container. Downloads and SQL execution
are mocked; the tests use temporary files inside that container. Docker may need
to download the Python image on the first run.

```bash
docker run --rm \
  --mount "type=bind,src=$PWD,dst=/workspace,readonly" \
  --workdir /workspace \
  python:3.14-bookworm python3 -B -m unittest discover -s tests
```

The procedure for updating Virtuoso data is as follows:  
* https://docs.google.com/spreadsheets/d/12JjDHkd4k9oI5Xme_Isyg9nqUsHU1PZvmvz5DQPKNZc/edit?gid=1150718828#gid=1150718828  

[!IMPORTANT]  
If you are unable to access the documentation links above, please contact the DBCLS team.
