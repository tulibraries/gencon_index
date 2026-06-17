# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/gencon_index"

RSpec.describe GenconIndex::CLI do
  describe ".harvest" do
    it "delegates to HarvestCSV with provided options" do
      expect(GenconIndex::HarvestCSV).to receive(:harvest)
        .with("data.csv", "map.yml", "http://localhost:8983/solr", 250)

      described_class.harvest(
        csv_file: "data.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 250
      )
    end

    it "uses the checked-in solr_map.yml by default during harvest" do
      csv_path = SPEC_FIXTURES_DIR.join("1980.csv")
      project_root = File.expand_path("../..", __dir__)
      solr_client = instance_double(RSolr::Client)
      progress_bar = instance_double(ProgressBar::Base)
      added_documents = []

      allow(RSolr).to receive(:connect).with(url: "http://localhost:8983/solr").and_return(solr_client)
      allow(solr_client).to receive(:commit)
      allow(solr_client).to receive(:add) do |batch|
        added_documents.concat(batch)
      end
      allow(ProgressBar).to receive(:create).and_return(progress_bar)
      allow(progress_bar).to receive(:increment)

      Dir.chdir(project_root) do
        described_class.harvest(
          csv_file: csv_path.to_s,
          solr_url: "http://localhost:8983/solr",
          batch_size: 500
        )
      end

      expect(added_documents).to include(
        hash_including(
          "year_display" => "1980",
          "year_facet" => "1980",
          "title_display" => "Alien Worlds Introductory Scenario",
          "title_t" => "Alien Worlds Introductory Scenario",
          "game_id_display" => "45",
          "id" => "1980-45"
        )
      )
    end
  end

  describe ".makemap" do
    it "opens the target file and hands it to HarvestCSV.make_map" do
      output_path = SPEC_TMP_DIR.join("map.yml")
      expect(GenconIndex::HarvestCSV).to receive(:make_map) do |csv_file, map_file, id_field|
        expect(csv_file).to eq("input.csv")
        expect(map_file).to be_a(File)
        expect(map_file.path).to eq(output_path.to_s)
        expect(id_field).to eq("id")
      end

      described_class.makemap(csv_file: "input.csv", id: "ID", map: output_path.to_s)
    end
  end

  describe ".blconfig" do
    it "delegates to HarvestCSV.blacklight with supplied file paths" do
      expect(GenconIndex::HarvestCSV).to receive(:blacklight)
        .with("map.yml", "partial.rb")

      described_class.blconfig(mapfile: "map.yml", output: "partial.rb")
    end
  end

  describe ".commit" do
    it "sends a commit to the configured Solr endpoint" do
      solr_client = instance_double(RSolr::Client)
      allow(RSolr).to receive(:connect).with(url: "http://localhost:8983/solr").and_return(solr_client)
      allow(solr_client).to receive(:commit)

      described_class.commit(solr_url: "http://localhost:8983/solr")

      expect(solr_client).to have_received(:commit)
    end
  end

  describe ".harvest_all" do
    it "processes all matching CSV files in sorted order" do
      output = StringIO.new

      allow(Dir).to receive(:[]).with("/tmp/gencon/*.csv").and_return(
        ["/tmp/gencon/a.csv", "/tmp/gencon/b.csv"]
      )

      expect(described_class).to receive(:harvest).with(
        csv_file: "/tmp/gencon/a.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 25
      ).ordered

      expect(described_class).to receive(:harvest).with(
        csv_file: "/tmp/gencon/b.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 25
      ).ordered

      described_class.harvest_all(
        directory: "/tmp/gencon",
        pattern: "*.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 25,
        output: output
      )

      expect(output.string).to include("process /tmp/gencon/a.csv")
      expect(output.string).to include("process /tmp/gencon/b.csv")
    end
  end
end
