require 'byebug'
module AssetCore
  module AssetScopes

    include ::Plugins::EngineCallbacks
    extend ::AssetCore::Configuration::ConfigBuilder

    mattr_accessor :scoped_classes
    @@scoped_classes = {}

    def self.add_scoped_classes scope, klass
      @@scoped_classes[scope.to_sym] ||= []
      @@scoped_classes[scope.to_sym] << klass
    end

    def self.get_scoped_classes scope
      @@scoped_classes[scope.to_sym] || []
    end

    DEFAULT_OPTS = {
      record_relationships: {},
      entry_callbacks: {
        before_validation: nil,
        validate: nil,
        after_validation: nil,
        before_save: nil,
        after_save: nil,
      },
      entry_methods: {},
      proxy_methods: {}
    }

    mattr_accessor :default_scopes
    # @@default_scopes = {
    #   acquisition: {
    #     record_relationships: {
    #       has_one: [:acquisition_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
    #     },
    #     entry_callbacks: {
    #       before_validation: nil,
    #       validate: proc {
    #         if record.entries.by_entry_scopes("acquisition").where.not(id: id).exists?
    #           errors.add(:type, :invalid)
    #         end
    #       },
    #       after_validation: nil,
    #       before_save: nil,
    #       after_save: nil,
    #     },
    #     entry_methods: {
    #       initial_value: 0,
    #       initial_value_currency: "IDR"
    #     },
    #     proxy_methods: {
    #       initial_value: proc {
    #         record.acquisition_entry&.initial_value
    #       },
    #       initial_value_currency: proc {
    #         record.acquisition_entry&.initial_value_currency
    #       }
    #     }
    #   },
    #   purchase: {
    #     entry_callbacks: {
    #       before_validation: nil,
    #       validate: nil,
    #       after_validation: nil,
    #       before_save: nil,
    #       after_save: proc {
    #         if state == "approved" && saved_change_to_state?
    #           if record && record.asset
    #             asset_state = asset_ownership_states.new( record: record , index_name: "owned", use_reference_data: true)
    #             asset_state.save
    #           end
    #         end
    #       },
    #     },
    #     entry_methods: {
    #       purchase_value: proc {
    #         data.price
    #       },
    #       purchase_currency: proc {
    #         data.currency
    #       }
    #     },
    #     proxy_methods: {
    #       purchase_value: proc {
    #         record.entries.approved.by_entry_scopes("purchase").order(:effective_at, :desc).first.purchase_value
    #       },
    #       purchase_currency: proc {
    #         record.entries.approved.by_entry_scopes("purchase").order(:effective_at, :desc).first.purchase_currency
    #       }
    #     }
    #   },
    #   depreciation: {
    #     record_relationships: {
    #       has_one: [:depreciation_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:depreciation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
    #     },
    #     entry_callbacks: {
    #       before_validation: nil,
    #       validate: proc {
    #         if record.entries.by_entry_scopes("depreciation").where.not(id: id).exists?
    #           errors.add(:type, :invalid)
    #         end
    #       },
    #       after_validation: nil,
    #       before_save: nil,
    #       after_save: nil
    #     },
    #     entry_methods: {
    #       initial_value: proc {
    #         record.acquisition_entry.try(:initial_value)
    #       },
    #       start_date: :created_at,
    #       residual_value: 0,
    #       expected_lifespan: 0,
    #       expected_lifespan_unit: "year",
    #       depreciation_method: "straight_line",
    #       rate: 0
    #     },
    #     proxy_methods: {}
    #   }
    # }

    def self.add_default_scope_with mod
      key = mod.name.demodulize.underscore.to_sym
      opts = mod.scope_options.inject({}) do |hash, (k, v)|
        hash[k]= plugins_config.build(**v)
        hash
      end
      @@default_scopes[key]= opts.dup
    end

        def self.scopes
      if @@_scopes.nil?
        @@_scopes= plugins_config.build()
        @@default_scopes.dup.each do |key, value|
          opts = value.inject({}) do |hash, (k, v)|
            hash[k]= plugins_config.build(**v)
            hash
          end
          define_scope(key, opts)
        end
      end
      @@_scopes
    end

    mattr_accessor :scopes
    @@scopes = plugins_config.build()


    def self.default_scope_opts
      opts = {}
      DEFAULT_OPTS.inject({}) do |hash, (key, value)|
        hash[key]= plugins_config.build(**value.dup)
        hash
      end
      opts
    end

    def self.setup &block
      raise "Block is not provided" unless block_given?
      block.arity.zero? ? instance_eval(&block) : yield(self)
    end

    def self.define_scope *args, &block

      default_opts = default_scope_opts

      opts = args.extract_options!
      opts = default_opts.merge(opts)
      scope = args[0]

      unless scope
        raise "Scope name is required"
      end
      if scopes.exists?(scope)
        raise "Scope name is already exists"
      end

      config =  plugins_config.build(**opts)
      if block_given?
        config.with_dynamic_keys do
          setup(&block)
        end
      end
      self.scopes.add(scope.to_sym, config)
    end

    module Core

      extend ::AssetCore::Configuration::ConfigBuilder
      include ::Plugins::EngineCallbacks

      def self.extended mod
        mod.include ::Plugins::EngineCallbacks
        mod.extend ::AssetCore::Configuration::ConfigBuilder
        mod.before_asset_core_initialization do
          key = mod.try(:scope_name) || mod.name.demodulize.underscore
          opts = mod.scope_options.inject({}) do |hash, (k, v)|
            hash[k]= plugins_config.build(**v)
            hash
          end
          ::AssetCore::AssetScopes.define_scope(key.to_sym, opts)
        end
      end

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