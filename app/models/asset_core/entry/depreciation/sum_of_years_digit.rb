module AssetCore
  class Entry::Depreciation::SumOfYearsDigit < AssetCore::Entry::Depreciation::Calculator

    self.method_name = :sum_of_years_digit

    def calculate(period: nil)
      entries = calculate_entries
      period ? group_by_period(entries, period) : entries
    end

    def calculate_entries
      total_value = initial_value - residual_value
      n = total_periods
      denominator = (n * (n + 1)) / 2.0

      entries = []

      period_intervals.each do |index|
        date = advance_time(index)
        break if date >= current_date

        numerator = n - index + 1
        depreciation = (total_value * numerator / denominator).round(2)

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