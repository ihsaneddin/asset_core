module AssetCore
  module AssetScopesd

    # include ::Plugins::EngineCallbacks
    # extend ::AssetCore::Configuration::ConfigBuilder

    # mattr_accessor :scoped_classes
    # @@scoped_classes = {}

    # def self.add_scoped_classes scope, klass
    #   @@scoped_classes[scope.to_sym] ||= []
    #   @@scoped_classes[scope.to_sym] << klass
    # end

    # def self.get_scoped_classes *_scopes
    #   _scopes.inject([]) do |arr, scope|
    #     arr + @@scoped_classes[scope.to_sym] || []
    #   end
    # end

    # DEFAULT_OPTS = {
    #   record_methods: {},
    #   record_relationships: {},
    #   entry_callbacks: {
    #     before_validation: nil,
    #     validate: nil,
    #     after_validation: nil,
    #     before_save: nil,
    #     after_save: nil,
    #   },
    #   entry_methods: {},
    #   proxy_methods: {}
    # }

    # mattr_accessor :scopes
    # @@scopes = plugins_config.build()


    # def self.default_scope_opts
    #   opts = {}
    #   DEFAULT_OPTS.inject({}) do |hash, (key, value)|
    #     hash[key]= plugins_config.build(**value.dup)
    #     hash
    #   end
    #   opts
    # end

    # def self.setup &block
    #   raise "Block is not provided" unless block_given?
    #   block.arity.zero? ? instance_eval(&block) : yield(self)
    # end

    # def self.define_scope *args, &block

    #   default_opts = default_scope_opts

    #   opts = args.extract_options!
    #   opts = default_opts.merge(opts)
    #   scope = args[0]

    #   unless scope
    #     raise "Scope name is required"
    #   end
    #   if scopes.exists?(scope)
    #     raise "Scope name is already exists"
    #   end

    #   config =  plugins_config.build(**opts)
    #   if block_given?
    #     config.with_dynamic_keys do
    #       setup(&block)
    #     end
    #   end
    #   self.scopes.add(scope.to_sym, config)
    # end

    # module Core

    #   extend ::AssetCore::Configuration::ConfigBuilder
    #   include ::Plugins::EngineCallbacks

    #   def self.extended mod
    #     mod.include ::Plugins::EngineCallbacks
    #     mod.extend ::AssetCore::Configuration::ConfigBuilder
    #     mod.before_asset_core_initialization do
    #       key = mod.try(:scope_name) || mod.name.demodulize.underscore
    #       opts = mod.scope_options.inject({}) do |hash, (key, val)|
    #         ctx = val.inject({}) do |res, (k, v)|
    #           res[k]= plugins_config.build(**v)
    #           res
    #         end
    #         hash[key] = plugins_config.build(**ctx)
    #         hash
    #       end
    #       ::AssetCore::AssetScopes.define_scope(key.to_sym, opts)
    #     end
    #   end

    # end

    # module Entries
    #   extend ::AssetCore::Configuration::ConfigBuilder
    #   include ::Plugins::EngineCallbacks

    #   mattr_accessor :extended_by_modules

    #   def self.extended mod
    #     mod.include ::Plugins::EngineCallbacks
    #     mod.extend ::AssetCore::Configuration::ConfigBuilder
    #     mod.mattr_accessor :options, :scope
    #     key = mod.try(:scope) || mod.name.demodulize.underscore
    #     mod.scope = key
    #     mod.options = mod.plugins_config.build(**default_scope_opts)
    #   end

    #   DEFAULT_OPTS = {
    #     relationships: {},
    #     callbacks: {
    #       before_validation: nil,
    #       validate: nil,
    #       after_validation: nil,
    #       before_save: nil,
    #       after_save: nil,
    #     },
    #     instance_methods: {}
    #   }

    #   def self.default_scope_opts
    #     opts = {}
    #     DEFAULT_OPTS.inject({}) do |hash, (key, value)|
    #       hash[key]= plugins_config.build(**value.dup)
    #       hash
    #     end
    #     opts
    #   end

    #   def define_scope *args, &block
    #     default_opts = default_scope_opts
    #     opts = args.extract_options!
    #     opts = default_opts.merge(opts)
    #     if args[0]
    #       self.scope = args[0]
    #     end
    #     unless self.scope
    #       raise "Scope name is required"
    #     end

    #     if block_given?
    #       options.with_dynamic_keys do
    #         setup(&block)
    #       end
    #     end

    #   end

    # end

    # module Records

    # end

    # Dir.glob(AssetCore::Engine.root.join("lib/asset_core/asset_scopes/**/*.rb")).each do |file|
    #   require_dependency file
    # end

    # before_asset_core_initialization do
    #   if Rails.root
    #     Dir.glob(Rails.root.join("lib/asset_core/asset_scopes/**/*.rb")).each do |file|
    #       require_dependency file
    #     end
    #   end
    # end

  end
end