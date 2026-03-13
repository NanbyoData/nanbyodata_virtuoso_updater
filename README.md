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

The procedure for updating Virtuoso data is as follows:  
* https://docs.google.com/spreadsheets/d/12JjDHkd4k9oI5Xme_Isyg9nqUsHU1PZvmvz5DQPKNZc/edit?gid=1150718828#gid=1150718828  

[!IMPORTANT]  
If you are unable to access the documentation links above, please contact the DBCLS team.  
