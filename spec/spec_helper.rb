# frozen_string_literal: true

require "bundler/setup"
require "active_support"
require "active_support/core_ext/string/inflections"
require "fileutils"
require "pathname"
require "factory_bot"

SPEC_ROOT = Pathname.new(__dir__)
SPEC_TMP_DIR = SPEC_ROOT.join("tmp")
FileUtils.mkdir_p(SPEC_TMP_DIR)
support_path = SPEC_ROOT.join("support", "**", "*.rb")
Dir[support_path].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.include FactoryBot::Syntax::Methods

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  config.example_status_persistence_file_path = SPEC_ROOT.join("examples.txt")
  Kernel.srand config.seed

  config.after(:suite) do
    FileUtils.rm_rf(Dir[SPEC_TMP_DIR.join("*")])
  end
end

FactoryBot.definition_file_paths = [
  SPEC_ROOT.join("factories")
]
FactoryBot.find_definitions
