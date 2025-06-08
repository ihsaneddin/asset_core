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

            unless reflect_on_association(:asset_records)
              has_many :asset_records, class_name: "AssetCore::Record", as: :owner

              accepts_nested_attributes_for :asset_records, allow_destroy: true

              ::AssetCore::Record.include(::Plugins::Models::Concerns::PolymorphicAlternative) unless include?(Plugins::Models::Concerns::PolymorphicAlternative)
              assoc_name = "owner_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::Record.define_alternative_polymorphic_parent_association assoc: :asset, new_assoc: assoc_name, base_class: self.base_class
            end

            include InstanceMethods unless include?(InstanceMethods)

          end

        end

        module InstanceMethods

          def asset_owner_name
            asset_owner_config_name
          end

          def asset_owner_address
            asset_owner_config_address
          end

          def asset_owner_contanct_number
            asset_owner_config_contact_number
          end

        end

      end
    end
  end
end
