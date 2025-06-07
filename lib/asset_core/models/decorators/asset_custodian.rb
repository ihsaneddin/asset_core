module AssetCore
  module Models
    module Decorators
      module AssetCustodian

        def self.included base
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.extend ClassMethods
        end

        module ClassMethods

          def asset_custodian **opts, &block
          end

        end

      end
    end
  end
end
