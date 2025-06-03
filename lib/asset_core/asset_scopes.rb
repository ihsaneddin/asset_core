module AssetCore
  module AssetScopes

    mattr_accessor :entry_scopes
    @@entry_scopes = {}

    def self.add_entry_scope(scope, mod)
      self.entry_scopes[scope] = mod
    end

    def scopes
      ::Plugins::Models::Config.new(
        {
          entries: ::Plugins::Models::Config.new(
            self.entry_scopes.inject({}){ |hash, (scope, mod)|
              hash[scope] = ::Plugins::Models::Config.new(mod.model_options)
            }
          ),
          proxy: ::Plugins::Models::Config.new(
            self.entry_scopes.inject({}){ |hash, (scope, mod)|
              hash[scope] = ::Plugins::Models::Config.new(mod.proxy_options)
            }
          ),
        }
      )
    end

  end
end