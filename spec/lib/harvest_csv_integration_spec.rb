# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/harvest_csv"

RSpec.describe "HarvestCSV integration with production CSV fixtures" do
  let(:schema_map) { YAML.load_file("solr_map.yml") }
  let(:fixture_paths) do
    %w[
      spec/fixtures/sample_data_2001.csv
      spec/fixtures/sample_data_2002.csv
      spec/fixtures/sample_data_2012.csv
    ]
  end

  describe ".csv_to_solr" do
    it "reads and transforms at least one row from each production CSV fixture" do
      fixture_paths.each do |fixture_path|
        csv = CSV.read(fixture_path, headers: true, encoding: "utf-8")

        expect(csv.headers).not_to be_nil, "expected headers in #{fixture_path}"
        expect(csv.headers).not_to be_empty, "expected non-empty headers in #{fixture_path}"
        expect(csv.first).not_to be_nil, "expected at least one row in #{fixture_path}"

        document = HarvestCSV.csv_to_solr(csv.first.to_h, schema_map)

        expect(document["id"]).to be_a(String), "expected generated id for #{fixture_path}"
        expect(document["id"]).not_to be_empty, "expected generated id for #{fixture_path}"
        expect(document["title_display"]).to be_a(String), "expected title_display for #{fixture_path}"
        expect(document["title_display"]).not_to be_empty, "expected title_display for #{fixture_path}"
        expect(document["year_display"]).to be_a(String), "expected year_display for #{fixture_path}"
        expect(document["year_display"]).not_to be_empty, "expected year_display for #{fixture_path}"
      end
    end
  end

  describe ".harvest" do
    let(:solr_client) { instance_double(RSolr::Client) }
    let(:progress_bar) { instance_double(ProgressBar::Base, increment: nil) }

    before do
      allow(RSolr).to receive(:connect).and_return(solr_client)
      allow(solr_client).to receive(:add)
      allow(solr_client).to receive(:commit)
      allow(ProgressBar).to receive(:create).and_return(progress_bar)
    end

    it "batches documents from each production CSV fixture without parse errors" do
      harvested_documents = []
      mutex = Mutex.new

      allow(solr_client).to receive(:add) do |batch, options|
        expect(options).to eq(add_attributes: { commitWithin: 10 })
        mutex.synchronize { harvested_documents.concat(batch) }
      end

      fixture_paths.each do |fixture_path|
        harvested_documents.clear

        HarvestCSV.harvest(fixture_path, "solr_map.yml", "http://example.com/solr", 50)

        expect(harvested_documents).not_to be_empty, "expected documents harvested from #{fixture_path}"
        representative_document = harvested_documents.find do |document|
          document["id"].is_a?(String) &&
            !document["id"].empty? &&
            document["title_display"].is_a?(String) &&
            !document["title_display"].empty? &&
            document["year_display"].is_a?(String) &&
            !document["year_display"].empty?
        end
        failure_message = "expected mapped document fields in harvested batches for #{fixture_path}"

        expect(representative_document).not_to be_nil, failure_message
      end
    end
  end
end
