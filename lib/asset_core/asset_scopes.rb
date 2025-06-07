module AssetCore
  module AssetScopes

    extend ::AssetCore::Configuration::ConfigBuilder

    DEFAULT_OPTS = {
      callbacks: {
        before_validation: nil,
        validate: nil,
        after_validation: nil,
        before_save: nil,
        after_save: nil,
      },
      functions: {},
      proxy: {}
    }

    DEFAULT_SCOPES = {
      acquisition: {
        callbacks: {
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
        functions: {
          initial_value: 0
        },
        proxy: {
          initial_value: proc {
            debugger
            record.entries.approved.by_entry_scopes("acquisition").first.initial_value
          }
        }
      },
      purchase: {
        callbacks: {
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
        functions: {
          purchase_value: proc {
            data.price
          },
          purchase_currency: proc {
            data.currency
          }
        },
        proxy: {
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