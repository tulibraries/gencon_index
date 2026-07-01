# frozen_string_literal: true

require "faraday"
require "rsolr"

module GenconIndex
  module SolrConfig
    module_function

    def client(solr_url, solr_user, solr_password)
      return RSolr.connect(url: solr_url) if solr_url.nil? || solr_user.to_s.empty?

      RSolr.connect(connection(solr_user, solr_password), url: solr_url)
    end

    def connection(solr_user, solr_password)
      Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }) do |conn|
        case Faraday::VERSION
        when /^0/
          conn.basic_auth solr_user, solr_password
        when /^1/
          conn.request :basic_auth, solr_user, solr_password
        else
          conn.request :authorization, :basic, solr_user, solr_password
        end

        conn.response :raise_error
        conn.adapter Faraday.default_adapter || :net_http
      end
    end
  end
end
