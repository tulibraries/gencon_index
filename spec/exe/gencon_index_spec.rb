# frozen_string_literal: true

require "spec_helper"

require_relative "../../lib/gencon_index"
load File.expand_path("../../exe/gencon_index", __dir__)

RSpec.describe GenconIndex::App do
  around do |example|
    original_gencon_temp_path = ENV["GENCON_TEMP_PATH"]
    original_solr_url = ENV["SOLR_URL"]
    ENV.delete("GENCON_TEMP_PATH")
    ENV.delete("SOLR_URL")
    example.run
  ensure
    ENV["GENCON_TEMP_PATH"] = original_gencon_temp_path if original_gencon_temp_path
    ENV["SOLR_URL"] = original_solr_url if original_solr_url
    ENV.delete("GENCON_TEMP_PATH") unless original_gencon_temp_path
    ENV.delete("SOLR_URL") unless original_solr_url
  end

  def capture_command(*args)
    stdout = $stdout
    stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    result = described_class.run(args)
    { result: result, stdout: $stdout.string, stderr: $stderr.string }
  ensure
    $stdout = stdout
    $stderr = stderr
  end

  def run_command(...)
    capture_command(...)[:result]
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
        directory: "./csv",
        pattern: "*.csv",
        mapfile: "map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 50
      )

      run_command(
        "harvest_all",
        "--directory=./csv",
        "--pattern=*.csv",
        "--mapfile=map.yml",
        "--solr_url=http://localhost:8983/solr",
        "--batch_size=50"
      )
    end

    it "uses GENCON_TEMP_PATH as the default harvest_all directory when set" do
      ENV["GENCON_TEMP_PATH"] = "/tmp/gencon"

      expect(GenconIndex::CLI).to receive(:harvest_all).with(
        directory: "/tmp/gencon",
        pattern: "*.csv",
        mapfile: "solr_map.yml",
        solr_url: nil,
        batch_size: 100
      )

      run_command("harvest_all")
    end

    it "uses SOLR_URL for harvest_all when no CLI options are given" do
      ENV["SOLR_URL"] = "http://localhost:8983/solr"

      expect(GenconIndex::CLI).to receive(:harvest_all).with(
        directory: "./csv",
        pattern: "*.csv",
        mapfile: "solr_map.yml",
        solr_url: "http://localhost:8983/solr",
        batch_size: 100
      )

      run_command("harvest_all")
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

    it "uses SOLR_URL for commit when no CLI options are given" do
      ENV["SOLR_URL"] = "http://localhost:8983/solr"

      expect(GenconIndex::CLI).to receive(:commit).with(
        solr_url: "http://localhost:8983/solr"
      )

      run_command("commit")
    end

    it "surfaces harvest errors instead of silently swallowing them" do
      allow(GenconIndex::CLI).to receive(:harvest).and_raise(StandardError, "solr unavailable")
      output = capture_command("harvest", "--mapfile=map.yml", "data.csv")

      expect(output[:result]).to eq(1)
    end
  end
end
