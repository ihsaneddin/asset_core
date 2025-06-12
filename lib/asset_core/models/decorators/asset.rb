require 'securerandom'
module AssetCore
  module Models
    module Decorators
      module Asset

        def self.included(base)
          extend ::AssetCore::Configuration::ConfigBuilder
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.extend ClassMethods
        end

        def self.default_options
          {
            proxy_class: 'AssetCore::Models::AssetProxy',
            name: nil,
            description: nil,
            owner: nil,
            number_generator: proc { SecureRandom.hex(8) },
            tag_number_generator: proc { SecureRandom.hex(8) },
            sync_data: 'sync', # options are none, async, sync
            quantity_unit_group_name: nil,
            quantity_unit_group: ::AssetCore.config.asset_quantities.groups.values[:count],
            depreciation_calculator_class: AssetCore.config.asset_depreciation_methods.calculator_class,
            defaults: plugins_config.build(currency: nil, entry_use_reference_data: false, state_use_reference_data: false),  # ::Plugins::Models::Config.new({currency: nil, manufacture: nil, owner: nil, entry_use_reference_data: false, state_use_reference_data: false}),
            entries: plugins_config.build(**::AssetCore::Entry.subclasses.inject({}) do |hash, entry_class|
              hash[entry_class.entry_name.to_sym] = entry_class.asset_record_entry_config
              hash
            end),
            states: plugins_config.build(**::AssetCore::State.subclasses.inject({}) do |hash, state_class|
              hash[state_class.state_name.to_sym] = state_class.asset_record_state_config
              hash
            end)
          }
        end

        module ClassMethods

          def acts_as_an_asset *args, &block
            return unless ActiveRecord::Base.connection.table_exists?('asset_core_entries')

            opts = args.extract_options!
            _type = args[0] || "single"
            asset_class = ::AssetCore::Record.find_by_asset_type(_type)

            unless asset_class < ::AssetCore::Record
              raise "Invalid asset type '#{_type}'"
            end

            default_opts = AssetCore::Models::Decorators::Asset.default_options

            plugins_config.setup(self, 'asset_config', opts, default_opts, &block)

            qty_unit_group_name = asset_config.quantity_unit_group_name
            if qty_unit_group_name.present?
              qty_unit_groups = :: AssetCore.config.asset_quantities.groups.dup
              raise "Invalid quantity_unit_group_name" unless qty_unit_groups.exists?(qty_unit_group_name)
              unit_group = qty_unit_groups.values[qty_unit_group_name].dup
              asset_config.set!(:quantity_unit_group, unit_group)
            end

            unless reflect_on_association(:asset_record)
              has_one :asset_record, class_name: asset_class.name, as: :asset, dependent: :destroy
              #has_one "asset_#{asset_class.asset_type}".to_sym, class_name: asset_class.name, as: :asset

              accepts_nested_attributes_for :asset_record

              ::AssetCore::Record.include(::Plugins::Models::Concerns::PolymorphicAlternative) unless include?(Plugins::Models::Concerns::PolymorphicAlternative)
              assoc_name = "asset_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::Record.define_alternative_polymorphic_parent_association assoc: :asset, new_assoc: assoc_name, base_class: self.base_class

            end

            include InstanceMethods

          end

        end

        module InstanceMethods

          def asset
            @asset_proxy ||= ::AssetCore::Models::AssetProxy.new(self)
          end

          def asset_quantity_unit_group
            ::AssetCore::AssetQuantityGroups.groups.send(asset_config.quantity_unit_group)
          end

        end

        module SyncCallbacks
          extend ActiveSupport::Concern

          included do

            attr_accessor :asset_data

            after_initialize :set_asset_data
            after_save :set_asset_data

            before_commit if: :asset_data_changes? do
              if asset_config.sync == 'sync'
                asset_sync_data
              elsif asset_config.sync == 'async'
                AssetCore::AssetWorker.perform_at(DateTime.now, nil, 'data_sync', *[self.class.name, self.id])
              end
            end
          end

          def set_asset_data
            self.asset_data = {
              name: asset_config_name,
              description: asset_config_description
            }
          end

          def asset_data_changes?
            current_asset_data = {
              name: asset_config_name,
              description: asset_config_description
            }
            !(Hashdiff.diff(current_asset_data, asset_data).empty?)
          end

          def asset_sync_data
            if asset_record
              current_asset_data = {
                name: asset_config_name,
                description: asset_config_description
              }
              asset_record.name= current_asset_data[:name]
              asset_record.description = current_asset_data[:description]
              asset_record.save
            end
          end

        end

      end
    end
  end
end