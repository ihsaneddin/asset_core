module AssetCore
  class Entry::Depreciation::Attributes < AssetCore::Attributes
    attribute :start_date, :date
    attribute :expected_lifespan, :integer, default: 0
    attribute :expected_lifespan_unit, :string, default: 'year'
    attribute :residual_value, :decimal, default: nil
    attribute :currency, :string
    attribute :rate, :decimal, default: nil
    attribute :depreciation_method, :string, default: 'straight_line'
    attribute :purchase_price, :decimal

    validates :start_date, timeliness: { type: :date, allow_blank: true }
    validates :expected_lifespan, numericality: { greater_than: 0 }, allow_blank: true
    validates :expected_lifespan_unit, inclusion: { in: %w[day week month year] }, allow_blank: true
    validates :residual_value, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
    validates :rate, numericality: { greater_than_or_equal_to: 0 }, if: :rate_is_required?
    validates :depreciation_method, inclusion: { in: AssetCore::Entry::Depreciation.depreciation_methods }, allow_blank: true
    validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

    def rate_is_required?
      method_class&.requires_rate?
    end

    def method_class
      AssetCore::Entry::Depreciation::Calculator.find_by_method_name(depreciation_method)
    end
  end
end