---
title: Gencon indexing (gencon_index)
author: Steven Ng
date: 2025-03-18
---

# GenCon Indexing (`gencon_index`)

## Purpose

`gencon_index` is a Ruby-based CSV-to-Solr ingester for event data from past Gen Con gaming conventions. It reads CSV records, uses a configurable mapping file to translate source columns into Solr fields, builds Solr documents, and submits those records to Apache Solr for indexing.

## Requirements

Requires Ruby 3.4.0+

This indexer targets SolrCloud. A local SolrCloud is included in this repo via
`docker-compose.yml` and the Solr configset in `solr/gencon50-solr`.

## Install

Install the gem dependencies (generally we do this in an rvm gemset)

    bin/setup

Create the local environment file

    cp .env.example .env

Set `SOLR_URL` in `.env` to the current Gencon50 collection or alias URL.

For local development, `make load-data` expects the local Docker SolrCloud settings from `.env.example`.

## Configure for Solr

`gencon_index` loads `.env` for CLI usage. For local development, use the default local SolrCloud settings:

    SOLR_PORT=8090
    SOLR_HOSTNAME=localhost
    SOLR_HOST=http://${SOLR_HOSTNAME}:${SOLR_PORT}
    SOLR_COLLECTION=gencon50-dev
    SOLR_URL=${SOLR_HOST}/solr/${SOLR_COLLECTION}

### Local development workflow

Start the local SolrCloud services:

    make up

Load the checked-in CSV data from `./csv` into the local collection:

    make load-data

Send a commit to the configured Solr endpoint:

    make commit

`make load-data` bootstraps the local SolrCloud state for this repo from `solr/gencon50-solr`. It waits for Solr, prepares the configset from `solr/gencon50-solr`, creates the local collection and alias if needed, and then ingests the CSV files.

`make load-data` ingests the CSV files in `./csv` into the local `gencon50-dev` collection.

### Use an external SolrCloud

For a separate SolrCloud instance, such as `ansible-playbook-solrcloud`, start from the external-cluster example env file:

    cp .env.solrcloud.example .env

Update the values in `.env` for the target cluster:

- `SOLR_SCHEME` should match the target SolrCloud protocol when it is not `http`.
- `SOLR_HOSTNAME` should be the hostname for the target SolrCloud instance.
- `SOLR_USER` and `SOLR_PASSWORD` are used by `make load-data` for authenticated Solr admin requests.
- `SOLR_HOST` should remain credential-free base Solr host and port.
- `SOLR_URL` is the endpoint used by the CLI for ingest/commit.
- `SOLR_PORT` should match the published Solr port for that environment.
- `SOLR_COLLECTION` should be the target collection or alias name.

`make load-data` uses `SOLR_HOST` for Solr admin endpoints and passes `SOLR_USER` / `SOLR_PASSWORD` separately for HTTP basic auth when they are set.

Example:

    SOLR_SCHEME=http
    SOLR_HOSTNAME=solrcloud.example.org
    SOLR_HOST=${SOLR_SCHEME}://${SOLR_HOSTNAME}:${SOLR_PORT}
    SOLR_COLLECTION=gencon50-v3.0.1
    SOLR_URL=${SOLR_HOST}/solr/${SOLR_COLLECTION}

When using an external SolrCloud, this repo assumes the target collection or alias already exists.

Run the executable directly from the repo

    bundle exec gencon_index help

`make load-data` uses `SOLR_USER` / `SOLR_PASSWORD` for Solr admin requests, but `make commit` and the `gencon_index` CLI use `SOLR_URL`. If your target Solr requires authentication for update requests, configure `SOLR_URL` so it is usable by the CLI in that environment.

## Commands

### Harvest a CSV File

To seed the database with a CSV file from the command line, use the following command. Replace `path/to/datafile.csv`
with the path to the file to upload.

    bundle exec gencon_index harvest --mapfile=solr_map.yml PATH/TO/datafile.csv

### Harvest all CSV files from a directory

    bundle exec gencon_index harvest_all --directory=./csv --pattern='*.csv' --mapfile=solr_map.yml

For the repo’s standard local workflow, use `make load-data`.

### Generate a mapping file

    bundle exec gencon_index makemap --id=ID --map=solr_map.yml PATH/TO/datafile.csv

### Generate a Blacklight config partial

    bundle exec gencon_index blconfig --output=_blacklight_config.rb solr_map.yml

## Commit to Solr

    bundle exec gencon_index commit --solr-url=http://localhost:8090/solr/gencon50-dev

Or:

    make commit

## Development Commands

Start local SolrCloud services

    make up

Load all checked-in CSVs from `./csv` into the local collection

    make load-data

Send a commit to Solr

    make commit

Test gencon_index

    make test

Lint gencon_index

    make lint
