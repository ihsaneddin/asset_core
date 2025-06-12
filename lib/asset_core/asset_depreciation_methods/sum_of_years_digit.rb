module AssetCore
  module AssetDepreciationMethods
    module SumOfYearsDigit
      extend ::AssetCore::AssetDepreciationMethods::Core

      def calculate_entries(*args)
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

end