# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/gencon_index"
load File.expand_path("../../exe/gencon_index", __dir__)

RSpec.describe GenconIndex::App do
  def run_command(*args)
    stdout = $stdout
    stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    described_class.run(args)
  ensure
    $stdout = stdout
    $stderr = stderr
  end

  describe ".run" do
    it "dispatches the harvest command" do
      expect(GenconIndex::CLI).to receive(:harvest).with(
        csv_file: "data.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 250
      )

      run_command("harvest", "--mapfile=map.yml", "--solr-url=http://localhost:8983/solr", "--batch-size=250",
                  "data.csv")
    end

    it "dispatches the harvest_all command" do
      expect(GenconIndex::CLI).to receive(:harvest_all).with(
        directory: "/tmp/gencon",
        pattern: "*.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 50
      )

      run_command(
        "harvest_all",
        "--directory=/tmp/gencon",
        "--pattern=*.csv",
        "--mapfile=map.yml",
        "--solr_url=http://localhost:8983/solr",
        "--batch_size=50"
      )
    end

    it "dispatches the makemap command" do
      expect(GenconIndex::CLI).to receive(:makemap).with(
        csv_file: "input.csv",
        id: "Identifier",
        map: "custom_map.yml"
      )

      run_command("makemap", "--id=Identifier", "--map=custom_map.yml", "input.csv")
    end

    it "dispatches the blconfig command" do
      expect(GenconIndex::CLI).to receive(:blconfig).with(
        mapfile: "map.yml",
        output: "partial.rb"
      )

      run_command("blconfig", "--output=partial.rb", "map.yml")
    end

    it "dispatches the commit command" do
      expect(GenconIndex::CLI).to receive(:commit).with(
        solr_url: "http://localhost:8983/solr"
      )

      run_command("commit", "--solr-url=http://localhost:8983/solr")
    end
  end
end
