# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/gencon_index"

RSpec.describe GenconIndex::SolrConfig do
  describe ".client" do
    it "builds an RSolr client for an unauthenticated URL" do
      solr_client = instance_double(RSolr::Client)

      expect(RSolr).to receive(:connect).with(url: "http://localhost:8983/solr").and_return(solr_client)

      result = described_class.client("http://localhost:8983/solr", nil, nil)

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
