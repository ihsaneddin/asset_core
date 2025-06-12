module AssetCore
  class Record::Single < ::AssetCore::Record

    class Attributes < ::AssetCore::Record::Attributes

      attribute :information, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_type :single, scopes: [ :acquisited, :purchased, :donated, :depreciated, :released ] do
      depreciated do
        functions do
          initial_value do
            acquisition_value || depreciation_entry&.initial_value || 0
          end
          initial_value_currency do
            acquisition_value_currency || asset.asset_config.defaults.currency
          end
          depreciation_start_date do
            acquisition_date || depreciation_entry&.start_date
          end
        end
        entry_callbacks do
          before_validation do |entry|
            entry.start_date ||= acquisition_date
          end
        end
      end
    end

  end
end
