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

  describe ".make_map" do
    let(:csv_path) { SPEC_FIXTURES_DIR.join("1980.csv") }
    let(:map_path) { SPEC_TMP_DIR.join("schema_map.yml") }

    it "builds a schema map for Solr fields from the fixture CSV" do
      described_class.make_map(csv_path, map_path, "Game ID")

      schema_map = YAML.load_file(map_path)
      expect(schema_map["game_id"]).to include("id", "game_id_display", "game_id_facet")
      expect(schema_map["original_order"]).to include("original_order_display", "original_order_facet")
      expect(schema_map["year"]).to include("year_display", "year_facet")
      expect(schema_map["title"]).to include("title_display", "title_facet")
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
    let(:map_path) { SPEC_FIXTURES_DIR.join("solr_map.yml") }
    let(:partial_path) { SPEC_TMP_DIR.join("blacklight_config.rb") }

    it "writes a Blacklight configuration partial" do
      described_class.blacklight(map_path, partial_path)

      partial = File.read(partial_path)
      expect(partial).to include("config.add_facet_field 'year_facet'")
      expect(partial).to include("config.add_show_field 'title_display'")
    end
  end

  describe ".harvest" do
    let(:map_path) { SPEC_FIXTURES_DIR.join("solr_map.yml") }
    let(:csv_path) { SPEC_FIXTURES_DIR.join("1980.csv") }
    let(:solr_url) { "http://example.com/solr" }
    let(:solr_client) { instance_double(RSolr::Client) }
    let(:progress_bar) { instance_double(ProgressBar::Base) }

    before do
      allow(RSolr).to receive(:connect).and_return(solr_client)
      allow(solr_client).to receive(:add)
      allow(solr_client).to receive(:commit)
      allow(ProgressBar).to receive(:create).and_return(progress_bar)
      allow(progress_bar).to receive(:increment)
    end

    it "transforms fixture CSV rows and sends them to Solr once per batch before committing" do
      added_batches = []

      expect(solr_client).to receive(:add).ordered do |batch|
        added_batches << batch
      end
      expect(solr_client).to receive(:commit).ordered

      described_class.harvest(csv_path, map_path, solr_url, 500)

      flattened_documents = added_batches.flatten

      expect(flattened_documents).to include(
        include(
          "id" => "1980-45",
          "year_display" => "1980",
          "title_display" => "Alien Worlds Introductory Scenario",
          "game_id_display" => "45"
        )
      )
      expect(progress_bar).to have_received(:increment).at_least(:once)
    end

    it "does not create threads during harvest" do
      expect(Thread).not_to receive(:new)

      described_class.harvest(csv_path, map_path, solr_url, 500)
    end

    it "raises errors from solr.add" do
      allow(solr_client).to receive(:add).and_raise(StandardError, "add failed")

      expect do
        described_class.harvest(csv_path, map_path, solr_url, 500)
      end.to raise_error(StandardError, "add failed")
    end

    it "uses an injected Solr client when provided" do
      injected_solr_client = instance_double(RSolr::Client, add: nil, commit: nil)

      expect(RSolr).not_to receive(:connect)

      described_class.harvest(
        csv_path,
        map_path,
        solr_url,
        500,
        solr_client: injected_solr_client
      )
    end
  end
end
