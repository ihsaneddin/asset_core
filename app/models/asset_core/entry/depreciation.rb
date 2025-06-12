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

      def rate_is_required?
        depreciation_method_class&.requires_rate?
      end

      def depreciation_methods
        AssetCore::Entry::Depreciation.depreciation_methods
      end

      def initial_value_is_required?
        return true unless parent
        if parent
          parent.record.acquisition_entry.nil?
        end
      end

      def start_date_is_required?
        if parent
          parent.record.acquisition_entry.nil?
        end
      end

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_scopes :depreciation

  end
end