setup:
	bin/setup

test:
	bundle exec rspec

lint:
	bundle exec rubocop
