# DEVO-1373 Structure Audit

AI-generated note for developer review.

This note captures the current behavior of `gencon_index` and the `cob_index` repository conventions that are worth copying later without introducing Traject.

## Current `gencon_index` behavior

### Executable entrypoints

- `exe/gencon_index` is the only Ruby CLI entrypoint shipped by the gem.
- The gemspec exposes that entrypoint as the installed command `gencon_index`.
- `harvest_notes.sh` exists as a repo-local helper script, but it is not part of the gem executable surface.

### Current command names and options

`exe/gencon_index` defines these GLI commands:

- `harvest csv-file`
  - `--mapfile`, default `solr_map.yml`
  - `--solr-url`, default `ENV["SOLR_URL"]`
  - `--batch-size`, default `100`
- `harvest_all`
  - `--directory`, default `/tmp/gencon`
  - `--pattern`, default `*.csv`
  - `--mapfile`, default `solr_map.yml`
  - `--solr-url`, default `ENV["SOLR_URL"]`
  - `--batch-size`, default `100`
- `makemap csv-file`
  - `--id`, default `ID`
  - `--map`, default `solr_map.yml`
- `blconfig map-file`
  - `--output`, default `_blacklight_config.rb`
- `commit`
  - `--solr-url`, default `ENV["SOLR_URL"]`

### Harvest workflow

- `harvest` delegates to `GenconIndex::HarvestCSV.harvest`.
- The workflow is CSV-driven, not endpoint-driven:
  - load the YAML field map from `solr_map.yml` or the supplied map file
  - read the entire CSV with `CSV.read(..., headers: true, encoding: "utf-8")`
  - normalize CSV headers with ActiveSupport inflections
  - map each row into a Solr document using the schema map
  - synthesize `id` from `original_order_display` when needed
  - prefix the `id` with `year_display` when present
  - strip commas and `#` from the final `id`
  - batch records and send them to Solr
  - commit at the end of the file
- `harvest_all` is a thin loop over `Dir[File.join(directory, pattern)]` and runs `harvest` once per matching file.
- There is no separate persisted harvest state, cursor, checkpoint, or upstream API client in the current implementation.

### Indexing workflow

- Harvesting and indexing are currently the same execution path.
- `harvest` performs both transformation and Solr adds.
- `commit` can also be run independently to send a commit to the configured Solr core/collection.
- `makemap` and `blconfig` are support utilities for generating mapping/config artifacts, not indexing steps.

### Configuration loading

- `lib/gencon_index/cli.rb` requires `dotenv/load`, so environment variables are loaded at process startup from `.env` if present.
- `SOLR_URL` is the only runtime environment variable used directly in the Ruby code.
- The checked-in `solr_map.yml` is the default mapping configuration.
- There is no central config object, no `bin/setup`, no Makefile-driven env bootstrap, and no multi-environment config layout.
- The README instructs the developer to copy `.env.example` to `.env`, but `.env.example` is not currently present in the repo.

### Solr interaction

- Solr writes are performed through `RSolr.connect(url: solr_url)`.
- `harvest` calls `solr.add(document_batch)` for each batch, then `solr.commit`.
- `commit` calls `RSolr.connect(...).commit`.
- There are no delete operations, no Solr query-time checks, and no Solr schema/config management in this repo.

### Current test coverage

- Specs are limited to unit/command-dispatch coverage:
  - `spec/exe/gencon_index_spec.rb`
  - `spec/lib/gencon_index_cli_spec.rb`
  - `spec/lib/harvest_csv_spec.rb`
  - `spec/factories/harvest.rb`
- Covered behavior includes:
  - CLI command dispatch
  - default map usage
  - CSV-to-Solr document mapping
  - ID generation and sanitization
  - map generation
  - Blacklight snippet generation
  - batch adds and commit behavior
  - `harvest_all` iteration
- The checked-in coverage report currently shows `100.0%` line coverage across `2` library files.
- There are no live Solr integration tests, no end-to-end command tests against a running service, and no fixture-heavy workflow tests.

### Commands documented in `README.md`

The README currently documents:

- `bundle install`
- `cp .env.example .env`
- `bundle exec gencon_index help`
- `bundle exec gencon_index harvest --mapfile=solr_map.yml path/to/datafile.csv`
- `bundle exec gencon_index harvest_all --directory=/tmp/gencon --pattern=*.csv --mapfile=solr_map.yml`
- `bundle exec gencon_index makemap --id=ID --map=solr_map.yml path/to/datafile.csv`
- `bundle exec gencon_index blconfig --output=_blacklight_config.rb solr_map.yml`
- `bundle exec gencon_index commit --solr-url=http://localhost:8090/solr/gencon50-<current-version>`

The README also documents a SolrCloud startup workflow through the separate `ansible-playbook-solrcloud` repository.

## `cob_index` structural patterns worth copying later

Only the conventions below appear reusable without bringing in Traject:

### Repository layout

- Separate `exe/` for the gem CLI and `bin/` for developer/support scripts.
- Keep top-level operational files predictable: `README.md`, `Gemfile`, gemspec, `Rakefile`, `Makefile`, `docker-compose.yml`.
- Use `docs`/subcomponent READMEs where a subsystem needs its own operator documentation.

### Executable organization

- Reserve `exe/` for the user-facing packaged command.
- Put developer convenience scripts in `bin/` such as `setup`, `console`, and data-loading helpers.

### Library/module organization

- Keep the root file small (`lib/<gem>.rb`) and load namespaced files from `lib/<gem>/`.
- Organize library code by responsibility in subdirectories instead of a flat `lib/` layout when the codebase grows.
- Keep non-code support assets under explicit library subdirectories when they are runtime dependencies.

### Test organization

- Mirror the library namespace under `spec/<gem>/...`.
- Keep fixtures under `spec/fixtures/...`.
- Use a single `spec/spec_helper.rb` with coverage and shared RSpec setup.
- Use `Rakefile` to expose `rake spec` as a standard entrypoint.

### Development tooling

- Provide `bin/setup` and `bin/console`.
- Provide a top-level `Makefile` for common local workflows.
- Keep CI workflows under `.github/workflows/` for lint/test automation.
- Keep RuboCop and coverage reporting wired into normal development.

### Documentation organization

- Keep the top-level README focused on developer onboarding and command usage.
- Split subsystem-specific operational docs into their own location instead of overloading the main README.

## `cob_index` patterns to ignore because they are Traject-specific

These should not be copied into `gencon_index`:

- Traject itself, including Traject gems, config files, macros, writers, or command flows.
- `ingest` and `delete` command patterns that exist to drive Traject/Nokogiri indexing.
- `lib/cob_index/indexer_config.rb`, `default_config.rb`, `delete_config.rb`, `suppress_config.rb`, `solr_json_writer.rb`, `nokogiri_indexer.rb`, and the `macros/` tree.
- MARCXML-specific fixtures, translation maps, and support data directories tied to MARC/Traject processing.
- The Solr config subproject and relevancy test harness under `solr/configs/...`.
- Any workflow that assumes Traject indexing configs are the primary unit of organization.

## Practical implication for the later refactor

The likely target is to make `gencon_index` look more like a conventional gem repo with clearer `bin/`, `lib/`, `spec/`, tooling, and docs boundaries, while leaving the current CSV harvest-to-Solr implementation and command behavior intact.
