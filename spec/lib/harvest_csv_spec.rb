# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/gencon_index"

RSpec.describe GenconIndex::HarvestCSV do
  describe ".csv_to_solr" do
    let(:schema_map) { build(:schema_map) }
    let(:csv_row) { build(:csv_row_hash) }

    it "maps CSV keys into Solr fields and generates an id" do
      document = described_class.csv_to_solr(csv_row, schema_map)

      expect(document["original_order_display"]).to eq("Z-100")
      expect(document["original_order_facet"]).to eq("Z-100")
      expect(document["year_display"]).to eq("2023")
      expect(document["year_facet"]).to eq("2023")
      expect(document["id"]).to eq("2023-Z-100")
    end

    it "preserves an existing id while sanitizing invalid characters" do
      custom_id_row = build(:csv_row_hash, identifier: "Custom,ID#42")
      document = described_class.csv_to_solr(custom_id_row, schema_map)

      expect(document["id"]).to eq("2023-CustomID42")
    end
  end

  describe ".sanitize" do
    it "strips non printable characters from strings" do
      clean_value = described_class.sanitize("Hello\u0000World")

      expect(clean_value).to eq("HelloWorld")
    end

    it "leaves non string values untouched" do
      expect(described_class.sanitize(123)).to eq(123)
    end
  end

  describe ".make_map" do
    let(:csv_path) { SPEC_TMP_DIR.join("sample.csv") }
    let(:map_path) { SPEC_TMP_DIR.join("schema_map.yml") }

    before do
      CSV.open(csv_path, "w") do |csv|
        csv << %w[ID Original\ Order Year]
        csv << %w[123 A1 2024]
      end
    end

    it "builds a schema map for Solr fields" do
      described_class.make_map(csv_path, map_path, "ID")

      schema_map = YAML.load_file(map_path)
      expect(schema_map["id"]).to include("id", "id_display", "id_facet")
      expect(schema_map["original_order"]).to include("original_order_display", "original_order_facet")
      expect(schema_map["year"]).to include("year_display", "year_facet")
    end
  end

  describe ".get_blacklight_add_fields" do
    let(:schema_map) do
      {
        "original_order" => %w[original_order_display original_order_facet],
        "year" => %w[year_display year_facet]
      }
    end

    it "extracts partial configuration for a matching field suffix" do
      facets = described_class.get_blacklight_add_fields(schema_map, "facet")

      expect(facets).to contain_exactly(
        hash_including(field: "original_order_facet", label: "Original Order"),
        hash_including(field: "year_facet", label: "Year")
      )
    end
  end

  describe ".blacklight" do
    let(:schema_map) do
      {
        "original_order" => %w[original_order_display original_order_facet],
        "year" => %w[year_display year_facet]
      }
    end
    let(:map_path) { SPEC_TMP_DIR.join("blacklight_map.yml") }
    let(:partial_path) { SPEC_TMP_DIR.join("blacklight_config.rb") }

    before do
      File.open(map_path, "w") { |file| YAML.dump(schema_map, file) }
    end

    it "writes a Blacklight configuration partial" do
      described_class.blacklight(map_path, partial_path)

      partial = File.read(partial_path)
      expect(partial).to include("config.add_facet_field 'original_order_facet'")
      expect(partial).to include("config.add_show_field 'original_order_display'")
    end
  end

  describe ".harvest" do
    let(:schema_map) { build(:schema_map) }
    let(:map_path) { SPEC_TMP_DIR.join("schema_map.yml") }
    let(:csv_path) { SPEC_TMP_DIR.join("harvest.csv") }
    let(:solr_url) { "http://example.com/solr" }
    let(:solr_client) { instance_double(RSolr::Client) }
    let(:progress_bar) { instance_double(ProgressBar::Base) }

    before do
      File.open(map_path, "w") { |file| YAML.dump(schema_map, file) }
      CSV.open(csv_path, "w") do |csv|
        csv << ["Original Order", "Year", "ID"]
        csv << ["ABC123", "2024", nil]
        csv << ["XYZ789", "2025", "Custom-99"]
      end

      allow(RSolr).to receive(:connect).and_return(solr_client)
      allow(solr_client).to receive(:add)
      allow(solr_client).to receive(:commit)
      allow(ProgressBar).to receive(:create).and_return(progress_bar)
      allow(progress_bar).to receive(:increment)
    end

    it "transforms CSV rows and sends them to Solr in batches" do
      documents = []
      mutex = Mutex.new

      allow(solr_client).to receive(:add) do |batch, options|
        expect(options).to eq(add_attributes: { commitWithin: 10 })
        mutex.synchronize { documents.concat(batch) }
      end

      described_class.harvest(csv_path, map_path, solr_url, 1)

      expect(documents.size).to eq(2)
      expect(documents.map { |doc| doc["id"] }).to contain_exactly("2024-ABC123", "2025-Custom-99")
      expect(solr_client).to have_received(:commit).at_least(:once)
      expect(progress_bar).to have_received(:increment).exactly(2).times
    end
  end
end
