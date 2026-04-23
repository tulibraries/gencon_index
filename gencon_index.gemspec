# frozen_string_literal: true

require_relative "lib/gencon_index/version"

Gem::Specification.new do |spec|
  spec.name = "gencon_index"
  spec.version = GenconIndex::VERSION
  spec.authors = ["Steven Ng"]
  spec.email = [""]

  spec.summary = "Executable wrapper for ingesting Gen Con CSV data into Solr"
  spec.description = "A gem-style CLI for harvesting CSV data and generating Solr mapping helpers."
  spec.homepage = "https://github.com/tulibraries/gencon_index"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.files = Dir[
    "README.md",
    "exe/*",
    "lib/**/*.rb",
    "solr_map.yml"
  ]
  spec.bindir = "exe"
  spec.executables = ["gencon_index"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 8.1"
  spec.add_dependency "csv", "~> 3.3"
  spec.add_dependency "dotenv", "~> 3.2"
  spec.add_dependency "gli", "~> 2.22"
  spec.add_dependency "logger", "~> 1.7"
  spec.add_dependency "rsolr", "~> 2.6"
  spec.add_dependency "ruby-progressbar", "~> 1.13"
  spec.add_dependency "yaml", "~> 0.4.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
