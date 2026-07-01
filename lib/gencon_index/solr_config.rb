# frozen_string_literal: true

require "faraday"
require "rsolr"

module GenconIndex
  module SolrConfig
    module_function

    def client(solr_url, solr_user, solr_password)
      connection = Faraday.new(url: solr_url) do |faraday|
        faraday.request(:authorization, :basic, solr_user, solr_password) unless solr_user.to_s.empty?
        faraday.adapter(Faraday.default_adapter)
      end

      RSolr.connect(connection, url: solr_url)
    end
  end
end