module AssetCore
  class Entry::Depreciation::DecliningBalance < AssetCore::Entry::Depreciation::Calculator
    self.method_name = :declining_balance

    def self.requires_rate?
      true
    end

    def calculate(period: nil)
      entries = calculate_entries
      period ? group_by_period(entries, period) : entries
    end

    def calculate_entries
      raise ArgumentError, "Rate must be present for declining balance method" unless rate
      entries = []
      current_value = initial_value
      accumulated = 0.0
      intervals = period_intervals

      intervals.each_with_index do |index, i|
        date = advance_time(index)
        break if date >= current_date

        depreciation = (current_value * rate.to_f).round(2)
        remaining = initial_value - accumulated

        # Do not depreciate below residual value
        if depreciation > (remaining - residual_value)
          depreciation = (remaining - residual_value).round(2)
        end

        accumulated += depreciation
        current_value -= depreciation

        entries << {
          year: nil,
          month: nil,
          week: nil,
          day: nil,
          index: index,
          value: depreciation,
          date: date
        }.merge(group_label(index))
      end

      entries
    end
  end
end