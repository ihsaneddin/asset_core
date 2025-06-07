module AssetCore
  class Entry::Depreciation::StraightLine < AssetCore::Entry::Depreciation::Calculator
    self.method_name = :straight_line

    def total_months
      case lifespan_unit
      when 'day'   then (lifespan.to_f / 30).ceil
      when 'week'  then (lifespan.to_f * 7 / 30).ceil
      when 'month' then lifespan
      when 'year'  then lifespan * 12
      else
        raise ArgumentError, "Unsupported lifespan_unit: #{lifespan_unit}"
      end
    end

    def month_intervals
      (1..total_months).to_a
    end

    def calculate_entries
      total = amount - residual_value
      monthly = (total / total_months.to_f).round(2)

      month_intervals.map do |month|
        date = purchase_date.advance(months: month - 1)
        {
          year: (month - 1) / 12 + 1,
          month: month,
          amount: monthly,
          date: date
        }
      end.select { |entry| entry[:date] <= as_of_date }
    end
  end
end