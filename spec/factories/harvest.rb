# frozen_string_literal: true

FactoryBot.define do
  factory :schema_map, class: Hash do
    transient do
      fields do
        {
          "Original Order" => %w[original_order_display original_order_facet],
          "Year" => %w[year_display year_facet],
          "ID" => %w[id id_display id_facet]
        }
      end
    end

    initialize_with { fields.transform_keys { |header| header.parameterize.underscore } }
  end

  factory :csv_row_hash, class: Hash do
    transient do
      original_order { "Z-100" }
      year { "2023" }
      identifier { nil }
    end

    initialize_with do
      {
        "Original Order" => original_order,
        "Year" => year,
        "ID" => identifier
      }
    end
  end
end
