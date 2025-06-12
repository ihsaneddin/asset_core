module AssetCore
  module AssetDepreciationMethods

    include ::Plugins::EngineCallbacks
    extend ::AssetCore::Configuration::ConfigBuilder

    mattr_accessor :_methods
    @@_methods = plugins_config.build(**{})

    mattr_accessor :calculator_class
    @@calculator_class = "AssetCore::AssetDepreciationMethods::Calculator"

    module Core
      mattr_accessor :extended_by_modules
      @@extended_by_modules = []

      def self.extended mod
        mod.extended_by_modules << mod
        mod.mattr_accessor :method_name, :options
        mod.method_name = mod.name.demodulize.underscore.to_sym
        mod.options = ::AssetCore::AssetDepreciationMethods.plugins_config.build(**{calculate: :calculate, calculate_entries: :calculate_entries})
        mod.define_method :calculate do |period=ni|
          entries = calculate_entries
          period ? group_by_period(entries, period) : entries
        end
        mod.define_method :calculate_entries do |*args|
          []
        end
      end

      def define_depreciation_method *args, &block
        opts = args.extract_options!
        if args[0]
          self.method_name = args[0]
        end
        unless self.method_name
          raise "Depreciation method name name is required"
        end
        if block_given?
          options.setup(**opts, &block)
        else
          options.setup(**opts)
        end
      end

    end

    def self.define_depreciation_method *args, &block
      opts = args.extract_options!
      method_name = args[0]

      raise "Depreciation method name is required" if group.blank?

      if calculate_methods.exists?(method_name)
        raise "Depreciation method #{method_name} is already existed"
      end

      default_opts = {
        calculate: proc { |period=nil|
          entries = calculate_entries
          period ? group_by_period(entries, period) : entries
        },
        calculate_entries: proc {|*args| [] }
      }
      opts = default_opts.merge(opts)
      config = plugins_config.build(**opts)

      if block_given?
        config.setup(**opts, &block)
      else
        config.setup(**opts)
      end
      @@_methods.add(method_name.to_sym, config)
    end

    def self.calculate_methods
      opts = Core.extended_by_modules.inject({}) do |hash, mod|
        options = mod.options.dup
        if options.values[:calculate].is_a?(Symbol)
          options.set(:calculate, mod.instance_method(:calculate))
        end
        if options.values[:calculate_entries].is_a?(Symbol)
          options.set(:calculate, mod.instance_method(:calculate_entries))
        end
        hash[mod.method_name.to_sym] = options
        hash
      end
      opts = @@_methods.values.inject(opts) do |hash, ( k,v )|
        hash[key.to_sym] = v
        hash
      end
      plugins_config.build(**opts)
    end

    class Calculator
      attr_reader :start_date, :lifespan, :lifespan_unit, :residual_value, :initial_value, :current_date, :rate, :method_name, :depreciation_method

      def initialize(start_date:, lifespan:, lifespan_unit:, residual_value:, initial_value:, current_date: Date.today, rate: nil, method_name: :straight_line)
        @start_date = start_date
        @lifespan = lifespan
        @lifespan_unit = lifespan_unit
        @residual_value = residual_value || default_residual_value
        @initial_value = initial_value
        @current_date = current_date
        @rate = rate || 0
        @method_name= method_name
        set_depreciation_method
      end

      def set_depreciation_method
        @depreciation_method ||= ::AssetCore::AssetDepreciationMethods.calculate_methods[method_name.to_sym].dup
        raise "Depreciation method #{method_name} not found" if @depreciation_method.nil?
        @depreciation_method.set_context(self)
        @depreciation_method
      end

      def default_residual_value
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

      def calculate(period= nil)
        depreciation_method.calculate(period)
      end

      def calculate_entries(*args)
        depreciation_method.calculate_entries(*args)
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
    end

    Dir.glob(AssetCore::Engine.root.join("lib/asset_core/asset_depreciation_methods/**/*.rb")).each do |file|
      require_dependency file
    end

    before_asset_core_initialization do
      if Rails.root
        Dir.glob(Rails.root.join("lib/asset_core/asset_depreciation_methods/**/*.rb")).each do |file|
          require_dependency file
        end
      end
    end

  end
end
