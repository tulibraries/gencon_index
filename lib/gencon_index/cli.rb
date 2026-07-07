# frozen_string_literal: true

require "dotenv/load"
require_relative "harvest_csv"
require_relative "solr_config"

module GenconIndex
  module CLI
    module_function

    def harvest(csv_file:, mapfile: "solr_map.yml", solr_url: nil, batch_size: 100)
      GenconIndex::HarvestCSV.harvest(
        csv_file,
        mapfile,
        solr_url,
        batch_size,
        solr: GenconIndex::SolrConfig.client(solr_url)
      )
    end

    # rubocop:disable Metrics/ParameterLists
    def harvest_all(directory: nil, pattern: "*.csv", mapfile: "solr_map.yml",
                    solr_url: nil,
                    batch_size: 100,
                    output: $stdout)
      directory = GenconIndex::SolrConfig.directory(directory)
      Dir[File.join(directory, pattern)].each do |file_name|
        file_path = File.expand_path(file_name)
        output.puts("process #{file_path}")
        harvest(
          csv_file: file_path,
          mapfile: mapfile,
          solr_url: solr_url,
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

    def commit(solr_url: nil)
      GenconIndex::SolrConfig.client(solr_url).commit
    end
  end
end
