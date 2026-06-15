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

This Blacklight instance requires SolrCloud. A local version of SolrCloud may be run
by using the TULibraries Ansible SolrCloud Playbook:
https://github.com/tulibraries/ansible-playbook-solrcloud

## Install

Install the gem dependencies (generally we do this in an rvm gemset)

    bin/setup

Create the local environment file

    cp .env.example .env

Set `SOLR_URL` in `.env` to the current Gencon50 collection URL.

## Configure for Solr

`gencon_index` loads `.env` for CLI usage. Ensure `.env` contains the current Gencon50 collection URL.

    SOLR_URL="http://localhost:8090/solr/gencon50-<current-version>"

### Start up SolrCloud

    cd /PATH/TO/ansible-playbook-solrcloud
    make up-lite
    cd /PATH/TO/gencon50

Run the executable directly from the repo

    bundle exec gencon_index help


## Commands

### Harvest a CSV File

To seed the database with a CSV file from the command line, use the following command. Replace `path/to/datafile.csv`
with the path to the file to upload.

    bundle exec gencon_index harvest --mapfile=solr_map.yml path/to/datafile.csv

### Harvest all CSV files from a directory

    bundle exec gencon_index harvest_all --directory=/tmp/gencon --pattern=*.csv --mapfile=solr_map.yml

### Generate a mapping file

    bundle exec gencon_index makemap --id=ID --map=solr_map.yml path/to/datafile.csv

### Generate a Blacklight config partial

    bundle exec gencon_index blconfig --output=_blacklight_config.rb solr_map.yml

## Commit to Solr

    bundle exec gencon_index commit --solr-url=http://localhost:8090/solr/gencon50-<current-version>

## Development Commands

Test gencon_index

    rake

Or

    make test

Lint gencon_index

    make lint
