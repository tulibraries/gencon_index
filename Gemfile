# frozen_string_literal: true

source "https://rubygems.org"
gemspec

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
