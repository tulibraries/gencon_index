# frozen_string_literal: true

require 'rubygems'
require 'csv'
require 'rsolr'
require 'yaml'
require 'securerandom'
require 'ruby-progressbar'
require 'uri'
require 'logger'
require 'active_support'
require 'active_support/core_ext/string/inflections'

module HarvestCSV
  def self.csv_to_solr(csv_hash, schema_map)
    document = {}
    csv_hash.each do |key, value|
      normalized_key = key.to_s.parameterize.underscore
      next unless schema_map.key?(normalized_key)

      schema_map[normalized_key].each do |solr_field|
        document[solr_field] = value
      end
    end

    # Gencon50 ID generation
    document['id'] ||= document['original_order_display']
    if document['id']
      document['id'] = document['id'].dup
      document['id'].prepend("#{document['year_display']}-") if document['year_display']
      document['id'].delete!(',')
      document['id'].delete!('#')
    end

    document
  end

  def self.sanitize(value)
    return value unless value.is_a?(String)

    value.gsub(/[^[:print:]]/, '')
  end

  def self.harvest(csv_source,
                   map_source = 'solr_map.yml',
                   solr_endpoint = ENV.fetch('SOLR_URL', nil),
                   batch_size = 100)
    logger = Logger.new($stdout)
    logger.info("Batch size = #{batch_size}")
    schema_map = YAML.load_file(map_source)
    batch_thread = []

    csv = CSV.read(csv_source, headers: true, encoding: 'utf-8')

    progressbar = ProgressBar.create(title: 'Harvest ', total: csv.count, format: '%t (%c/%C) %a |%B|')
    solr = RSolr.connect url: solr_endpoint
    csv.each_slice(batch_size) do |batch|
      batch_thread << Thread.new do
        document_batch = []
        batch.each do |item|
          document_batch << csv_to_solr(item.to_h, schema_map)
          progressbar.increment
        end
        solr.add document_batch, add_attributes: { commitWithin: 10 }
      end

      solr.commit

      batch_thread.each(&:join)
    end
  end

  def self.make_map(csv_path,
                    map_path,
                    id_field)
    schema_map = {}
    target_id_field = id_field.to_s.parameterize.underscore
    CSV.open(csv_path, headers: true) do |csv|
      csv.first
      csv.headers.each do |field_name|
        normalized_field = field_name.to_s.parameterize.underscore
        schema_map[normalized_field] = []
        schema_map[normalized_field] << 'id' if target_id_field == normalized_field
        schema_map[normalized_field] << "#{normalized_field}_display"
        schema_map[normalized_field] << "#{normalized_field}_facet"
      end
    end
    map_file = map_path.respond_to?(:write) ? map_path : File.new(map_path, 'w')
    YAML.dump(schema_map, map_file)
    map_file.close unless map_path.respond_to?(:write)
  end

  def self.get_blacklight_add_fields(schema_map, field_match)
    partial_fields = []
    schema_map.values.flatten.select do |a|
      next unless a.end_with?(field_match)

      partial_fields << {
        field: a.parameterize,
        label: a.sub(/_#{field_match}$/, '').titleize
      }
    end
    partial_fields
  end

  def self.blacklight(map_source = 'solr_map.yml', partial_output = '_blacklight_config.rb')
    schema_map = YAML.load_file(map_source)
    partial_file = partial_output.respond_to?(:write) ? partial_output : File.new(partial_output, 'w')
    line = String.new
    get_blacklight_add_fields(schema_map, 'facet').each do |f|
      line << "    config.add_facet_field '#{f[:field]}', label: '#{f[:label]}'\n"
    end
    get_blacklight_add_fields(schema_map, 'display').each do |f|
      line << "    config.add_show_field '#{f[:field]}', label: '#{f[:label]}'\n"
    end
    partial_file.write line
    partial_file.close unless partial_output.respond_to?(:write)
  end
end
