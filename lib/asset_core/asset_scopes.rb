module AssetCore
  module AssetScopes

    ENTRY_SCOPE_DEFAULT_OPTS = {
      relationships: {},
      callbacks: {
        before_validation: nil,
        validate: nil,
        after_validation: nil,
        before_save: nil,
        after_save: nil,
      },
      functions: {},
      attributes: [],
      requires: []
    }

    RECORD_SCOPE_DEFAULT_OPTS = {
      relationships: {},
      callbacks: {
        before_validation: nil,
        validate: nil,
        after_validation: nil,
        before_save: nil,
        after_save: nil,
      },
      functions: {},
      entry_scopes: [],
      entry_callbacks: {
        before_validation: nil,
        validate: nil,
        after_validation: nil,
        before_save: nil,
        after_save: nil,
      },
      requires: [],
      proxy: nil
    }

    extend ::AssetCore::Configuration::ConfigBuilder
    include ::Plugins::EngineCallbacks

    def self.build_opts base = {}
      opts = base.inject({}) do |hash, (key, value)|
        if value.is_a?(Hash)
          hash[key]= plugins_config.build(**value.dup)
        else
          hash[key]= value.try(:dup) || value
        end
        hash
      end
      opts
    end

    module Core

      def self.extended mod
        mod.mattr_accessor :extended_by_modules
        mod.extended_by_modules = []
      end

      def build_opts base = {}
        ::AssetCore::AssetScopes.build_opts(base)
      end

      def extended mod
        mod.extended_by_modules << mod
      end

    end

    module Entry
      extend ::AssetCore::Configuration::ConfigBuilder
      extend ::AssetCore::AssetScopes::Core

      def self.extended mod
        super(mod)
        mod.extend ::AssetCore::Configuration::ConfigBuilder
        mod.mattr_accessor :entry_scope_options, :entry_scope_name
        mod.entry_scope_name = mod.name.demodulize.underscore
        opts = build_opts(::AssetCore::AssetScopes::ENTRY_SCOPE_DEFAULT_OPTS)
        mod.entry_scope_options = mod.plugins_config.build(**opts)
      end

      def define_entry_scope *args, &block
        opts = args.extract_options!
        if args[0]
          self.entry_scope_name = args[0]
        end
        unless self.entry_scope_name
          raise "Entry scope name is required"
        end

        if block_given?
          entry_scope_options.relationships.dynamic_keys!
          entry_scope_options.functions.dynamic_keys!
          entry_scope_options.setup(**opts, &block)
          entry_scope_options.relationships.static_keys!
          entry_scope_options.functions.static_keys!
        else
          entry_scope_options.setup(**opts)
        end
      end

    end

    module Record
      extend ::AssetCore::Configuration::ConfigBuilder
      extend ::AssetCore::AssetScopes::Core

      def self.extended mod
        super(mod)
        mod.extend ::AssetCore::Configuration::ConfigBuilder
        mod.mattr_accessor :record_scope_options, :record_scope_name
        mod.record_scope_name = mod.name.demodulize.underscore
        opts = build_opts(::AssetCore::AssetScopes::RECORD_SCOPE_DEFAULT_OPTS)
        mod.record_scope_options = mod.plugins_config.build(**opts)
      end

      def define_record_scope *args, &block
        opts = args.extract_options!
        if args[0]
          self.record_scope_name = args[0]
        end
        unless self.record_scope_name
          raise "Record scope name is required"
        end

        if block_given?
          record_scope_options.relationships.dynamic_keys!
          record_scope_options.functions.dynamic_keys!
          record_scope_options.setup(**opts, &block)
          record_scope_options.relationships.static_keys!
          record_scope_options.functions.static_keys!
        else
          record_scope_options.setup(**opts)
        end
      end

    end

    mattr_accessor :_entry_scopes
    @@_entry_scopes = plugins_config.build(**{})

    def self.define_entry_scope *args, &block
      opts = args.extract_options!
      scope_name = args[0]
      unless scope_name
        raise "Scope name is required"
      end

      if entry_scopes.exists?(scope_name)
        raise "Scope #{scope_name} is already existed"
      end

      opts = ::AssetCore::AssetScopes::ENTRY_SCOPE_DEFAULT_OPTS.merge(opts)

      cfg = build_opts(**opts)

      if block_given?
        cfg.relationships.dynamic_keys!
        cfg.functions.dynamic_keys!
        cfg.setup(&block)
        cfg.relationships.static_keys!
        cfg.functions.static_keys!
      else
        cfg.setup(**opts)
      end

      @@_entry_scopes.add(scope_name.to_sym, cfg)

    end

    def self.entry_scopes
      opts = Entry.extended_by_modules.inject({}) do |hash, mod|
        hash[mod.entry_scope_name.to_sym] = mod.entry_scope_options
        hash
      end
      opts = @@_entry_scopes.values.inject(opts) do |hash, ( k,v )|
        hash[key.to_sym] = v
        hash
      end
      plugins_config.build(**opts)
    end

    def self.entry_scope_names
      entry_scopes.keys
    end

    mattr_accessor :_record_scopes
    @@_record_scopes = plugins_config.build(**{})

    def self.define_record_scope *args, &block
      opts = args.extract_options!
      scope_name = args[0]
      unless scope_name
        raise "Scope name is required"
      end

      if record_scopes.exists?(scope_name)
        raise "Scope #{scope_name} is already existed"
      end

      opts = ::AssetCore::AssetScopes::RECORD_SCOPE_DEFAULT_OPTS.merge(opts)

      cfg = build_opts(**opts)


      if block_given?
        cfg.relationships.dynamic_keys!
        cfg.functions.dynamic_keys!
        cfg.setup(&block)
        cfg.relationships.static_keys!
        cfg.functions.static_keys!
      else
        cfg.setup(**opts)
      end

      @@_record_scopes.add(scope_name.to_sym, cfg)
    end

    def self.record_scopes
      opts = Record.extended_by_modules.inject({}) do |hash, mod|
        hash[mod.record_scope_name.to_sym] = mod.record_scope_options
        hash
      end
      opts = @@_record_scopes.values.inject(opts) do |hash, ( k,v )|
        hash[key.to_sym] = v
        hash
      end
      plugins_config.build(**opts)
    end

    def self.record_scope_names
      record_scopes.keys
    end


    Dir.glob(AssetCore::Engine.root.join("lib/asset_core/asset_scopes/**/*.rb")).each do |file|
      require_dependency file
    end

    before_asset_core_initialization do
      if Rails.root
        Dir.glob(Rails.root.join("lib/asset_core/asset_scopes/**/*.rb")).each do |file|
          require_dependency file
        end
      end
    end

  end
end