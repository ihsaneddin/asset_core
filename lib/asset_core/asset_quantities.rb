module AssetCore
  module AssetQuantities

    include ::Plugins::EngineCallbacks
    extend ::AssetCore::Configuration::ConfigBuilder

    mattr_accessor :_groups
    @@_groups = plugins_config.build(**{})

    DEFAULT_OPTIONS = {
      base_unit: "unit",
      units: [{name: "unit", label: "Unit", factor: 1}],
      conversion: proc { |qty, from_unit, to_unit, precision=0|
        from_factor = units.find { |u| u[:name].to_s == from_unit.to_s }&.dig(:factor)
        to_factor   = units.find { |u| u[:name].to_s == to_unit.to_s }&.dig(:factor)
        unless from_factor && to_factor
          warn "Unknown unit(s)"
          qty
        else
          qty * (from_factor / to_factor)
        end

      }
    }

    module Core

      mattr_accessor :extended_by_modules
      @@extended_by_modules = []

      def self.extended mod
        mod.mattr_accessor :extended_by_modules
        extended_by_modules << mod
        mod.mattr_accessor :quantity_group_name, :options
        mod.quantity_group_name = mod.name.demodulize.underscore.to_sym
        mod.options = ::AssetCore::AssetQuantities.plugins_config.build(**{base_unit: :base_unit, units: :units, conversion: :conversion})
        # mod.define_method :base_unit do
        #   ::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:base_unit]
        # end
        # mod.define_method :units do
        #   ::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:units]
        # end
        # mod.define_method :conversion do |qty, from= nil, to= nil, precision= 0|
        #   instance_exec(qty, from, to, precision, &::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:conversion])
        # end
      end

      def define_quantity_group *args, &block
        opts = args.extract_options!
        if args[0]
          self.quantity_group_name = args[0]
        end
        unless self.quantity_group_name
          raise "Quantity group name name is required"
        end
        if block_given?
          options.setup(**opts, &block)
        else
          options.setup(**opts)
        end
      end

      def base_unit
        ::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:base_unit]
      end

      def units
        ::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:units]
      end

      def conversion qty, from= nil, to= nil, precision= 0
        instance_exec(qty, from, to, precision, &::AssetCore::AssetQuantities::DEFAULT_OPTIONS[:conversion])
      end

    end

    def self.define_quantity_group *args, &block
      opts = args.extract_options!
      group = args[0]

      raise "Quantity group name is required" if group.blank?

      if groups.exists?(group)
        raise "Quantity group #{group} is already existed"
      end

      default_opts = ::AssetCore::AssetQuantities::DEFAULT_OPTIONS
      opts = default_opts.merge(opts)
      config = plugins_config.build(**opts)

      if block_given?
        config.setup(**opts, &block)
      else
        config.setup(**opts)
      end
      @@_groups.add(group.to_sym, config)
    end

    def self.groups
      opts = Core.extended_by_modules.inject({}) do |hash, mod|
        options = mod.options.dup
        if options.values[:base_unit].is_a?(Symbol)
          options.set(:base_unit, mod.method(:base_unit).to_proc)
        end
        if options.values[:units].is_a?(Symbol)
          options.set(:units, mod.method(:units).to_proc)
        end
        if options.values[:conversion].is_a?(Symbol)
          options.set(:conversion, mod.method(:conversion).to_proc)
        end
        hash[mod.quantity_group_name.to_sym] = options
        hash
      end
      opts = @@_groups.values.inject(opts) do |hash, ( k,v )|
        hash[key.to_sym] = v
        hash
      end
      plugins_config.build(**opts)
    end

    Dir.glob(AssetCore::Engine.root.join("lib/asset_core/asset_quantity_groups/**/*.rb")).each do |file|
      require_dependency file
    end

    before_asset_core_initialization do
      if Rails.root
        Dir.glob(Rails.root.join("lib/asset_core/asset_quantity_groups/**/*.rb")).each do |file|
          require_dependency file
        end
      end
    end

  end
end
