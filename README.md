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

Set `SOLR_URL` in `.env` to the current Gencon50 collection URL.

## Configure for Solr

`gencon_index` loads `.env` for CLI usage. Ensure `.env` contains the current Gencon50 collection URL.

    SOLR_URL="http://localhost:8090/solr/gencon50-dev"

### Start up SolrCloud

    make up
    make reset

### Use an external SolrCloud

For a separate SolrCloud instance, such as `ansible-playbook-solrcloud`, start from
the external-cluster example env file instead of the local Docker one.

    cp .env.solrcloud.example .env

Update the values in `.env` for the target cluster:

- `SOLR_HOSTNAME` should be the hostname for the target SolrCloud instance.
- `SOLR_HOST` may include basic auth credentials when the SolrCloud instance requires them.
- `SOLR_URL` should point at the target collection or alias for that cluster.
- `SOLR_PORT` should match the published Solr port for that environment.

Example:

    SOLR_HOSTNAME=solrcloud.example.org
    SOLR_HOST=http://${SOLR_USER}:${SOLR_PASSWORD}@${SOLR_HOSTNAME}:${SOLR_PORT}
    SOLR_URL=${SOLR_HOST}/solr/gencon50-v3.0.1

Run the executable directly from the repo

    bundle exec gencon_index help


## Commands

### Harvest a CSV File

To seed the database with a CSV file from the command line, use the following command. Replace `path/to/datafile.csv`
with the path to the file to upload.

    bundle exec gencon_index harvest --mapfile=solr_map.yml PATH/TO/datafile.csv

### Harvest all CSV files from a directory

    bundle exec gencon_index harvest_all --directory=/tmp/gencon --pattern=*.csv --mapfile=solr_map.yml

### Generate a mapping file

    bundle exec gencon_index makemap --id=ID --map=solr_map.yml PATH/TO/datafile.csv

### Generate a Blacklight config partial

    bundle exec gencon_index blconfig --output=_blacklight_config.rb solr_map.yml

## Commit to Solr

    bundle exec gencon_index commit --solr-url=http://localhost:8090/solr/gencon50-dev

Or:

    make commit

## Development Commands

Show local SolrCloud state

    make solr-status

Load all checked-in CSVs from `./csv` into the local collection

    make load-data

Test gencon_index

    rake

Or

    make test

Lint gencon_index

    make lint
