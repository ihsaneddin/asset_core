module AssetCore
  module AssetScopes

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

    DEFAULT_SCOPES = {
      acquisition: {
        record_relationships: {
          has_one: [:acquisition_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
        },
        entry_callbacks: {
          before_validation: nil,
          validate: proc {
            if record.entries.by_entry_scopes("acquisition").where.not(id: id).exists?
              errors.add(:invalid, :record)
            end
          },
          after_validation: nil,
          before_save: nil,
          after_save: nil,
        },
        entry_methods: {
          initial_value: 0
        },
        proxy_methods: {
          initial_value: proc {
            acquisition_entry&.initial_value
            #record.entries.approved.by_entry_scopes("acquisition").first.initial_value
          }
        }
      },
      purchase: {
        entry_callbacks: {
          before_validation: nil,
          validate: nil,
          after_validation: nil,
          before_save: nil,
          after_save: proc {
            if state == "approved" && saved_change_to_state?
              if record && record.asset
                asset_state = asset_ownership_states.new( record: record , index_name: "owned")
                asset_state.approve!
              end
            end
          },
        },
        entry_methods: {
          purchase_value: proc {
            data.price
          },
          purchase_currency: proc {
            data.currency
          }
        },
        proxy_methods: {
          purchase_value: proc {
            record.entries.approved.by_entry_scopes("purchase").first.purchase_value
          },
          purchase_currency: proc {
            record.entries.approved.by_entry_scopes("purchase").first.purchase_currency
          }
        }
      }
    }

    mattr_accessor :_scopes
    @@_scopes = nil

    def self.setup &block
      raise "Block is not provided" unless block_given?
      block.arity.zero? ? instance_eval(&block) : yield(self)
    end

    def self.scopes
      if @@_scopes.nil?
        @@_scopes= plugins_config.build()
        DEFAULT_SCOPES.dup.each do |key, value|
          opts = value.inject({}) do |hash, (k, v)|
            hash[k]= plugins_config.build(**v)
            hash
          end
          define_scope(key, opts)
        end
      end
      @@_scopes
    end

    def self.define_scope *args, &block

      default_opts = DEFAULT_OPTS.inject({}) do |hash, (key, value)|
        hash[key]= plugins_config.build(**value.dup)
        hash
      end

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

  end
end