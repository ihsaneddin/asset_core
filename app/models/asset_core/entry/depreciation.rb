module AssetCore
  class Entry::Depreciation < AssetCore::Entry

    class Attributes < AssetCore::Attributes

      attribute :start_date, :date
      attribute :expected_lifespan, :integer, default: 1
      attribute :expected_lifespan_unit, :string, default: 'year'
      attribute :residual_value, :decimal, default: 0
      attribute :currency, :string
      attribute :rate, :decimal, default: 0
      attribute :depreciation_method, :string, default: 'straight_line'
      attribute :initial_value, :decimal

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :depreciation

  end
end