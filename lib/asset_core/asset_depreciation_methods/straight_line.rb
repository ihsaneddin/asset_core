module AssetCore
  module AssetDepreciationMethods
    module StraightLine
      extend ::AssetCore::AssetDepreciationMethods::Core

      def self.calculate_entries(*args)
        total = initial_value.to_d - residual_value.to_d
        monthly = (total / total_months).round(2)

        entries = month_intervals.map.with_index do |month_index, i|
          date = start_date.advance(months: month_index - 1)

          value =
            if i == total_months - 1
              # Adjust the final value to ensure total depreciation is accurate
              (total - monthly * (total_months - 1)).round(2)
            else
              monthly
            end

          {
            year: date.year,
            month: date.month,
            value: value.to_f, # return as float for compatibility
            date: date
          }
        end

        entries.select { |entry| entry[:date] <= current_date }
      end
    end
  end

end
