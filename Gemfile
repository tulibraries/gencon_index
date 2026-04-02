# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
gem "rsolr", ">= 1.0", "< 3"
gem "dotenv"
gem "yaml", "~> 0.4.0"
gem "securerandom", "~> 0.4.1"
gem "ruby-progressbar", "~> 1.13"
gem "uri", "~> 1.0", ">= 1.0.3"
gem "logger", "~> 1.6", ">= 1.6.6"
gem "thor", "~> 1.3", ">= 1.3.2"
gem "activesupport"
gem "csv", "~> 3.3"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "solr_wrapper", ">= 4.0.2"
  gem "pry"
  gem "rubocop", require: false
end

group :test do
  gem "factory_bot", "~> 6.4"
  gem "rspec", "~> 3.13"
end
