# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/gencon_index"

RSpec.describe GenconIndex::SolrConfig do
  describe ".client" do
    it "builds an RSolr client for an unauthenticated URL" do
      faraday = instance_double(Faraday::Connection)
      solr_client = instance_double(RSolr::Client)

      expect(Faraday).to receive(:new).with(url: "http://localhost:8983/solr").and_yield(faraday).and_return(faraday)
      expect(faraday).not_to receive(:request)
      expect(faraday).to receive(:adapter).with(Faraday.default_adapter)
      expect(RSolr).to receive(:connect).with(faraday, url: "http://localhost:8983/solr").and_return(solr_client)

      result = described_class.client("http://localhost:8983/solr", nil, nil)

      expect(result).to eq(solr_client)
    end

    it "passes through SOLR_AUTH_USER and SOLR_AUTH_PASSWORD values to Faraday basic auth" do
      faraday = instance_double(Faraday::Connection)
      solr_client = instance_double(RSolr::Client)

      expect(Faraday).to receive(:new).with(url: "http://localhost:8983/solr").and_yield(faraday).and_return(faraday)
      expect(faraday).to receive(:request).with(:authorization, :basic, "user", "secret")
      expect(faraday).to receive(:adapter).with(Faraday.default_adapter)
      expect(RSolr).to receive(:connect).with(faraday, url: "http://localhost:8983/solr").and_return(solr_client)

      result = described_class.client("http://localhost:8983/solr", "user", "secret")

      expect(result).to eq(solr_client)
    end
  end
end