module AssetCore
  module Models
    module Decorators
      module AssetOwner

        def self.included base
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.extend ClassMethods
        end

        def self.default_options
          {
            name: nil,
            address: nil,
            contact_number: nil
          }
        end

        module ClassMethods

          def asset_owner **opts, &block

            return unless ActiveRecord::Base.connection.table_exists?('asset_core_records')
            default_opts = AssetCore::Models::Decorators::AssetOwner.default_options

            plugins_config.setup(self, 'asset_owner_config', opts, default_opts, &block)

            unless reflect_on_association(:asset_states)
              has_many :asset_records, class_name: "AssetCore::Record", as: :owner

              accepts_nested_attributes_for :asset_records, allow_destroy: true
            end

            include InstanceMethods unless include?(InstanceMethods)

          end

        end

        module InstanceMethods

        end

      end
    end
  end
end
