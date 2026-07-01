# frozen_string_literal: true

require "dotenv/load"
require_relative "harvest_csv"

module GenconIndex
  module CLI
    module_function

    def harvest(csv_file:, mapfile: "solr_map.yml", solr_url: ENV.fetch("SOLR_URL", nil),
                solr_user: ENV.fetch("SOLR_AUTH_USER", nil),
                solr_password: ENV.fetch("SOLR_AUTH_PASSWORD", nil),
                batch_size: 100)
      GenconIndex::HarvestCSV.harvest(
        csv_file,
        mapfile,
        solr_url,
        batch_size,
        solr_client: GenconIndex::SolrConfig.client(solr_url, solr_user, solr_password)
      )
    end

    # rubocop:disable Metrics/ParameterLists
    def harvest_all(directory: ENV.fetch("GENCON_TEMP_PATH", "./csv"), pattern: "*.csv", mapfile: "solr_map.yml",
                    solr_url: ENV.fetch("SOLR_URL", nil),
                    solr_user: ENV.fetch("SOLR_AUTH_USER", nil),
                    solr_password: ENV.fetch("SOLR_AUTH_PASSWORD", nil),
                    batch_size: 100,
                    output: $stdout)
      Dir[File.join(directory, pattern)].each do |file_name|
        file_path = File.expand_path(file_name)
        output.puts("process #{file_path}")
        harvest(
          csv_file: file_path,
          mapfile: mapfile,
          solr_url: solr_url,
          solr_user: solr_user,
          solr_password: solr_password,
          batch_size: batch_size
        )
      end
    end
    # rubocop:enable Metrics/ParameterLists

    def makemap(csv_file:, id: "ID", map: "solr_map.yml")
      id_field = id.parameterize.underscore
      File.open(map, "w") do |map_file|
        GenconIndex::HarvestCSV.make_map(csv_file, map_file, id_field)
      end
    end

    def blconfig(mapfile: "solr_map.yml", output: "_blacklight_config.rb")
      GenconIndex::HarvestCSV.blacklight(mapfile, output)
    end

    def commit(solr_url: ENV.fetch("SOLR_URL", nil),
               solr_user: ENV.fetch("SOLR_AUTH_USER", nil),
               solr_password: ENV.fetch("SOLR_AUTH_PASSWORD", nil))
      GenconIndex::SolrConfig.client(solr_url, solr_user, solr_password).commit
    end
  end
end
