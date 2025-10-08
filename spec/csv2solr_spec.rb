# frozen_string_literal: true

require "spec_helper"

load File.expand_path("../csv2solr", __dir__) unless Object.const_defined?(:CSV2Solr)

RSpec.describe CSV2Solr do
  describe "#harvest" do
    it "delegates to HarvestCSV with provided options" do
      cli = described_class.new
      options = Thor::CoreExt::HashWithIndifferentAccess.new(
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr"
      )
      allow(cli).to receive(:options).and_return(options)

      expect(HarvestCSV).to receive(:harvest)
        .with("data.csv", "map.yml", "http://localhost:8983/solr")

      cli.harvest("data.csv")
    end
  end

  describe "#makemap" do
    it "opens the target file and hands it to HarvestCSV.make_map" do
      cli = described_class.new
      output_path = SPEC_TMP_DIR.join("map.yml")
      options = Thor::CoreExt::HashWithIndifferentAccess.new(
        id: "ID",
        map: output_path.to_s
      )
      allow(cli).to receive(:options).and_return(options)

      expect(HarvestCSV).to receive(:make_map) do |csv_file, map_file, id_field|
        expect(csv_file).to eq("input.csv")
        expect(map_file).to be_a(File)
        expect(map_file.path).to eq(output_path.to_s)
        expect(id_field).to eq("id")
      end

      cli.makemap("input.csv")
    end
  end

  describe "#blconfig" do
    it "delegates to HarvestCSV.blacklight with supplied file paths" do
      cli = described_class.new
      options = Thor::CoreExt::HashWithIndifferentAccess.new(
        output: "partial.rb"
      )
      allow(cli).to receive(:options).and_return(options)

      expect(HarvestCSV).to receive(:blacklight)
        .with("map.yml", "partial.rb")

      cli.blconfig("map.yml")
    end
  end
end
