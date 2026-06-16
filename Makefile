ifneq ("$(wildcard .env)","")
include .env
export
endif

SOLR_PORT ?= 8090
SOLR_HOST ?= http://localhost:$(SOLR_PORT)
SOLR_CONFIGSET ?= gencon50
SOLR_COLLECTION ?= gencon50-dev
SOLR_ALIAS ?= gencon50-current
SOLR_CONFIG_DIR ?= solr/gencon50-solr
SOLR_CONFIG_ZIP ?= /tmp/$(SOLR_CONFIGSET).zip
SOLR_CONFIG_STAGE_DIR ?= /tmp/$(SOLR_CONFIGSET)-configset
SOLR_URL ?= $(SOLR_HOST)/solr/$(SOLR_COLLECTION)
SOLR_WAIT_ATTEMPTS ?= 30
SOLR_WAIT_DELAY ?= 2

setup:
	bin/setup

test:
	bundle exec rspec

lint:
	bundle exec rubocop

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f solr zookeeper

solr-wait:
	@attempt=1; \
	until curl -fsS "$(SOLR_HOST)/solr/admin/info/system?wt=json" > /dev/null; do \
	  if [ $$attempt -ge $(SOLR_WAIT_ATTEMPTS) ]; then \
	    echo "Solr did not become ready at $(SOLR_HOST) after $(SOLR_WAIT_ATTEMPTS) attempts" >&2; \
	    exit 1; \
	  fi; \
	  echo "Waiting for Solr at $(SOLR_HOST) (attempt $$attempt/$(SOLR_WAIT_ATTEMPTS))"; \
	  attempt=$$((attempt + 1)); \
	  sleep $(SOLR_WAIT_DELAY); \
	done

solr-config-zip:
	@rm -rf $(SOLR_CONFIG_STAGE_DIR)
	@mkdir -p $(SOLR_CONFIG_STAGE_DIR)
	cp -R $(SOLR_CONFIG_DIR)/. $(SOLR_CONFIG_STAGE_DIR)
	@rm -rf $(SOLR_CONFIG_STAGE_DIR)/.git $(SOLR_CONFIG_STAGE_DIR)/.github
	@rm -f $(SOLR_CONFIG_STAGE_DIR)/README.md
	ruby -e 'path = ARGV.fetch(0); filtered = File.readlines(path).reject { |line| line.include?("analysis-extras/lib") }; File.write(path, filtered.join)' $(SOLR_CONFIG_STAGE_DIR)/solrconfig.xml
	@rm -f $(SOLR_CONFIG_ZIP)
	cd $(SOLR_CONFIG_STAGE_DIR) && find . -type f -print | sort | zip -q -@ $(SOLR_CONFIG_ZIP)

solr-config-upload: solr-wait solr-config-zip
	@if curl -fsS "$(SOLR_HOST)/solr/admin/configs?action=LIST&omitHeader=true&wt=json" | grep -q '"$(SOLR_CONFIGSET)"'; then \
	  echo "Configset $(SOLR_CONFIGSET) already exists"; \
	else \
	  curl -fsS -X POST \
	    --header "Content-Type: application/octet-stream" \
	    --data-binary @$(SOLR_CONFIG_ZIP) \
	    "$(SOLR_HOST)/solr/admin/configs?action=UPLOAD&name=$(SOLR_CONFIGSET)"; \
	fi

solr-collection-create: solr-wait
	@if curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=LIST&wt=json" | grep -q '"$(SOLR_COLLECTION)"'; then \
	  echo "Collection $(SOLR_COLLECTION) already exists"; \
	else \
	  curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=CREATE&name=$(SOLR_COLLECTION)&numShards=1&replicationFactor=1&maxShardsPerNode=1&collection.configName=$(SOLR_CONFIGSET)"; \
	fi

solr-alias-create: solr-wait
	curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=CREATEALIAS&name=$(SOLR_ALIAS)&collections=$(SOLR_COLLECTION)"

solr-bootstrap: solr-config-upload solr-collection-create solr-alias-create

solr-status: solr-wait
	curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=LIST&wt=json"
	curl -fsS "$(SOLR_HOST)/solr/admin/configs?action=LIST&omitHeader=true&wt=json"

solr-collection-delete:
	@if curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=LIST&wt=json" | grep -q '"$(SOLR_COLLECTION)"'; then \
	  curl -fsS "$(SOLR_HOST)/solr/admin/collections?action=DELETE&name=$(SOLR_COLLECTION)"; \
	else \
	  echo "Collection $(SOLR_COLLECTION) does not exist"; \
	fi

solr-config-delete:
	@if curl -fsS "$(SOLR_HOST)/solr/admin/configs?action=LIST&omitHeader=true&wt=json" | grep -q '"$(SOLR_CONFIGSET)"'; then \
	  curl -fsS "$(SOLR_HOST)/solr/admin/configs?action=DELETE&name=$(SOLR_CONFIGSET)"; \
	else \
	  echo "Configset $(SOLR_CONFIGSET) does not exist"; \
	fi

reset: solr-collection-delete solr-config-delete solr-bootstrap

load-data:
	SOLR_URL="$(SOLR_URL)" bundle exec gencon_index harvest_all --directory=./csv --pattern=*.csv --mapfile=solr_map.yml

commit:
	SOLR_URL="$(SOLR_URL)" bundle exec gencon_index commit
