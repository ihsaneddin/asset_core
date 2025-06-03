module AssetCore
  module Models
    module Decorators
      module Scopes
        module Entry
          module Depreciation

            extend ::AssetCore::AssetScopes::Entry

            def self.model_options
              opts = super

              opts
            end

            def self.proxy_options

            end

          end
        end
      end
    end
  end
end