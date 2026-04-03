# frozen_string_literal: true

require "spec_helper"

RSpec.describe "project configuration" do
  it "ships a parseable Solr schema map with an id mapping" do
    schema_map = YAML.load_file("solr_map.yml")

    expect(schema_map).to include("game_id")
    expect(schema_map["game_id"]).to include("id")
    expect(schema_map["title"]).to include("title_display")
  end
end
