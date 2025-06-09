module AssetCore
  class Entry::Depreciation::Calculator
    class_attribute :method_name

    attr_reader :start_date, :lifespan, :lifespan_unit, :residual_value, :initial_value, :current_date, :rate

    def initialize(start_date:, lifespan:, lifespan_unit:, residual_value:, initial_value:, current_date: Date.today, rate: nil)
      @start_date = start_date
      @lifespan = lifespan
      @lifespan_unit = lifespan_unit
      @residual_value = residual_value
      @initial_value = initial_value
      @current_date = current_date
      @rate = rate
    end

    def self.requires_rate?
      false
    end

    def self.default_residual_value(initial_value:)
      0.0
    end

    def total_periods
      lifespan
    end

    def period_intervals
      (1..total_periods).to_a
    end

    def advance_time(index)
      offset = index - 1
      case lifespan_unit
      when 'day'
        start_date + offset.days
      when 'week'
        start_date + (offset * 7).days
      when 'month'
        start_date.advance(months: offset)
      when 'year'
        start_date.advance(years: offset)
      else
        raise ArgumentError, "Unsupported lifespan_unit: #{lifespan_unit}"
      end
    end

    def group_label(index)
      date = advance_time(index)
      case lifespan_unit
      when 'day'
        { day: date.day, month: date.month, year: date.year }
      when 'week'
        { week: date.cweek, year: date.year }
      when 'month'
        { month: date.month, year: date.year }
      when 'year'
        { year: date.year }
      else
        {}
      end
    end

    def calculate(period: nil)
      entries = calculate_entries
      period ? group_by_period(entries, period) : entries
    end

    def calculate_entries
      raise NotImplementedError, "Subclasses must implement `calculate_entries`"
    end

    def group_by_period(entries, period)
      grouped = entries.group_by do |entry|
        date = entry[:date]
        case period.to_s
        when 'day'
          [date.year, date.month, date.day]
        when 'week'
          [date.cwyear, date.cweek]
        when 'month'
          [date.year, date.month]
        when 'year'
          [date.year]
        else
          raise ArgumentError, "Unsupported period: #{period}"
        end
      end

      grouped.map do |key, group|
        {
          period: key,
          initial_value: group.sum { |e| e[:initial_value] },
          entries: group
        }
      end
    end

    def self.find_by_method_name(name)
      class_name = "AssetCore::Entry::Depreciation::#{name.to_s.camelize}"
      klass = class_name.safe_constantize
      raise ArgumentError, "Depreciation method '#{name}' not found" unless klass && klass < self

      klass
    end
  end
end