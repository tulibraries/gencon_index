ifneq ("$(wildcard .env)","")
include .env
export
endif

setup:
	bin/setup

test:
	bundle exec rspec

lint:
	bundle exec rubocop

init:
	git submodule update --init --recursive

up: init
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f solr zookeeper

load-data: init
	bin/load-data

commit:
	bundle exec gencon_index commit
