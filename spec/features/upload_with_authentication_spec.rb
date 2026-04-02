# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/harvest_csv"

RSpec.describe HarvestCSV do
  describe ".blacklight" do
    let(:output_path) { SPEC_TMP_DIR.join("generated_blacklight_config.rb") }

    it "builds a Blacklight partial from the checked-in Solr schema map" do
      described_class.blacklight("solr_map.yml", output_path)

      partial = File.read(output_path)

      expect(partial).to include("config.add_facet_field 'event_type_facet', label: 'Event Type'")
      expect(partial).to include("config.add_show_field 'title_display', label: 'Title'")
      expect(partial).to include("config.add_show_field 'long_description_display', label: 'Long Description'")
    end
  end
end
