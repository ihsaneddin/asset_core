module AssetCore
  class Entry::Depreciation < AssetCore::Entry

    class << self
      def depreciation_methods
        Calculator.descendants.map(&:method_name).map(&:to_s)
      end
    end

    custom_attributes_definition :data, Attributes

    #TODO
    def purchase_price
      record.respond_to?(:purchase_price) ? record.purchase_price : 0.0
    end

    def residual_value
      if data.residual_value.present?
        data.residual_value
      else
        method_class.default_residual_value(amount: purchase_price)
      end
    end

    def method_class
      data.method_class
    end

    def depreciation_schedule(as_of: Date.today, period: nil)
      raise "Unknown depreciation method: #{data.depreciation_method}" unless method_class

      method_class.new(
        purchase_date: data.start_date,
        lifespan: data.expected_lifespan,
        lifespan_unit: data.expected_lifespan_unit,
        residual_value: residual_value,
        amount: purchase_price,
        as_of_date: as_of,
        rate: data.rate
      ).calculate(period: period)
    end

    def accrued_depreciation(as_of: Date.today)
      depreciation_schedule(as_of: as_of).sum { |entry| entry[:amount] }
    end

    def net_book_value(as_of: Date.today)
      purchase_price - accrued_depreciation(as_of: as_of)
    end
  end
end