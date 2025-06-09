require 'bigdecimal'
require 'bigdecimal/util'

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