---
title: CSV Data Ingester for The Best 50 Years in Gaming site
author: Steven Ng
date: 2025-03-18
---

# Ingesting CSV for The Best 50 Years in Gaming site to SolrCloud

## System Requirements

Requires Ruby 3.4.0+

This Blacklight instance requires SolrCloud. A local version of SolrCloud may be run
by using the TULibraries Ansible SolrCloud Playbook:
https://github.com/tulibraries/ansible-playbook-solrcloud

## Getting started

### Install

Install the gem dependencies (generally we do this in an rvm gemset)

    bundle install

Create the local environment file

    cp .env.example .env

Then set `SOLR_URL` in `.env` to the current Gencon50 collection URL.

## Configure for Solr

`gencon_index` loads `.env` for CLI usage. Ensure `.env` contains the current Gencon50 collection URL.

    SOLR_URL="http://localhost:8090/solr/gencon50-<current-version>"

### Start up SolrCloud

    cd ../ansible-playbook-solrcloud
    make up-lite
    cd ../gencon50

Run the executable directly from the repo

    bundle exec gencon_index help

Ingest some data

To seed the database with a CSV file from the command line, use the following command. Replace `path/to/datafile.csv`
with the path to the file to upload.

    bundle exec gencon_index harvest --mapfile=solr_map.yml path/to/datafile.csv

Harvest all CSV files from a directory

    bundle exec gencon_index harvest_all --directory=/tmp/gencon --pattern=*.csv --mapfile=solr_map.yml

Generate a mapping file from a CSV header

    bundle exec gencon_index makemap --id=ID --map=solr_map.yml path/to/datafile.csv

Generate a Blacklight config partial from the map

    bundle exec gencon_index blconfig --output=_blacklight_config.rb solr_map.yml

Send a commit to Solr

    bundle exec gencon_index commit --solr-url=http://localhost:8090/solr/gencon50-<current-version>
