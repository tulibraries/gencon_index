# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot.definition_file_paths = [
  SPEC_ROOT.join("factories")
]
FactoryBot.find_definitions
