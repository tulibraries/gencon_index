# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/gencon_index"

RSpec.describe GenconIndex::SolrConfig do
  around do |example|
    original_gencon_temp_path = ENV["GENCON_TEMP_PATH"]
    original_solr_url = ENV["SOLR_URL"]
    original_solr_user = ENV["SOLR_AUTH_USER"]
    original_solr_password = ENV["SOLR_AUTH_PASSWORD"]
    ENV.delete("GENCON_TEMP_PATH")
    ENV.delete("SOLR_URL")
    ENV.delete("SOLR_AUTH_USER")
    ENV.delete("SOLR_AUTH_PASSWORD")
    example.run
  ensure
    ENV["GENCON_TEMP_PATH"] = original_gencon_temp_path if original_gencon_temp_path
    ENV["SOLR_URL"] = original_solr_url if original_solr_url
    ENV["SOLR_AUTH_USER"] = original_solr_user if original_solr_user
    ENV["SOLR_AUTH_PASSWORD"] = original_solr_password if original_solr_password
    ENV.delete("GENCON_TEMP_PATH") unless original_gencon_temp_path
    ENV.delete("SOLR_URL") unless original_solr_url
    ENV.delete("SOLR_AUTH_USER") unless original_solr_user
    ENV.delete("SOLR_AUTH_PASSWORD") unless original_solr_password
  end

  describe ".directory" do
    it "falls back to GENCON_TEMP_PATH from ENV" do
      ENV["GENCON_TEMP_PATH"] = "/tmp/gencon"

      expect(described_class.directory).to eq("/tmp/gencon")
    end

    it "falls back to ./csv when no directory is configured" do
      expect(described_class.directory).to eq("./csv")
    end

    it "prefers the provided directory over ENV" do
      ENV["GENCON_TEMP_PATH"] = "/tmp/gencon"

      expect(described_class.directory("./custom")).to eq("./custom")
    end
  end

  describe ".client" do
    it "builds a plain RSolr client when passed an empty Solr auth user" do
      expect(RSolr).to receive(:connect).with(url: "http://localhost:8983/solr")

      described_class.client("http://localhost:8983/solr", "", nil)
    end

    it "falls back to SOLR_URL, SOLR_AUTH_USER, and SOLR_AUTH_PASSWORD from ENV" do
      ENV["SOLR_URL"] = "http://localhost:8983/solr"
      ENV["SOLR_AUTH_USER"] = "user"
      ENV["SOLR_AUTH_PASSWORD"] = "secret"

      solr_client = instance_double(RSolr::Client)
      allow(RSolr).to receive(:connect)
        .with(instance_of(Faraday::Connection), url: "http://localhost:8983/solr")
        .and_return(solr_client)

      result = described_class.client(nil, nil, nil)

      expect(result).to eq(solr_client)
    end

    it "passes through SOLR_AUTH_USER and SOLR_AUTH_PASSWORD values to Faraday basic auth" do
      solr_client = instance_double(RSolr::Client)

      allow(RSolr).to receive(:connect)
        .with(instance_of(Faraday::Connection), url: "http://localhost:8983/solr")
        .and_return(solr_client)

      result = described_class.client("http://localhost:8983/solr", "user", "secret")

      expect(result).to eq(solr_client)
    end

    it "does not interpolate URI-sensitive passwords into SOLR_URL" do
      solr_client = instance_double(RSolr::Client)
      allow(RSolr).to receive(:connect)
        .with(instance_of(Faraday::Connection), url: "http://localhost:8983/solr")
        .and_return(solr_client)

      expect do
        described_class.client("http://localhost:8983/solr", "user", "@:/?#%[]")
      end.not_to raise_error
    end
  end
end
