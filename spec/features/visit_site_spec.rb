# frozen_string_literal: true

require "spec_helper"
require "csv"
require_relative "../../lib/harvest_csv"

RSpec.describe HarvestCSV do
  describe ".csv_to_solr" do
    let(:schema_map) { YAML.load_file("solr_map.yml") }
    let(:csv_row) { CSV.read("spec/fixtures/sample_data_2001.csv", headers: true).first.to_h }

    it "maps a fixture row into a Solr document using the checked-in schema" do
      document = described_class.csv_to_solr(csv_row, schema_map)

      expect(document["id"]).to start_with("2001-")
      expect(document["id"]).to include("1099")
      expect(document["title_display"]).to eq("Acquire")
      expect(document["year_display"]).to eq("2001")
      expect(document["original_order_display"]).to eq("1")
    end
  end

  describe ".make_map" do
    let(:output_path) { SPEC_TMP_DIR.join("fixture_schema_map.yml") }

    it "normalizes sample CSV headers into underscored Solr field groups" do
      described_class.make_map("spec/fixtures/sample_data_2001.csv", output_path, "Original Order")

      schema_map = YAML.load_file(output_path)

      expect(schema_map["original_order"]).to include("id", "original_order_display", "original_order_facet")
      expect(schema_map["start_date_time"]).to include("start_date_time_display", "start_date_time_facet")
      expect(schema_map["cost"]).to include("cost_display", "cost_facet")
    end
  end
end
