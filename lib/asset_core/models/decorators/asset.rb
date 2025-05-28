require 'securerandom'
module AssetCore
  module Models
    module Decorators
      module Asset

        def self.included(base)
          extend ClassMethods
        end

        def self.default_options
          {
            asset_type: 'generic',
            name: nil,
            description: nil,
            number_generator: proc { SecureRandom.hex(8) },
            tag_number_generator: proc { SecureRandom.hex(8) },
            number_prefix: nil,
            number_suffix: nil,
            tag_number_prefix: nil,
            tag_number_suffix: nil,
            sync_data: 'sync', # options are none, async, sync
            defaults: ::Plugins::Models::Config.new({currency: nil, manufacture: nil, organization: nil, entry_use_reference_data: false, state_use_reference_data: false}),
            available_entries: proc { ::AssetCore::Record.find_by_asset_type(asset_config.asset_type).available_entries },
            available_states: proc { ::AssetCore::Record.find_by_asset_type(asset_config.asset_type).available_states },
            entries: ::Plugins::Models::Concerns::Config.new(::AssetCore::Entry.subclasses.inject({}) do |hash, entry_class|
              hash[entry_class.entry_name.to_sym] = entry_class.asset_record_entry_config
            end),
            states: ::Plugins::Models::Config.new(::AssetCore::State.subclasses..inject({}) do |hash, state_class|
              hash[state_class.state_name.to_sym] = state_class.asset_record_state_config
            end)
          }
        end

        module ClassMethods

          def acts_as_asset **opts, &block
            return unless ActiveRecord::Base.connection.table_exists?('asset_core_entries')

            default_opts = AssetCore::Models::Decorators::Asset.default_options
            opts = default_opts.merge(opts.slice(*default_opts.keys))

            ::Plugins::Models::Concerns::Config.setup(self, 'asset_config', opts, &block)

            asset_class = ::AssetCore::Record.find_by_asset_type(asset_config.asset_type)

            unless reflect_on_association(:asset_record)
              has_one :asset_record, class_name: "AssetCore::Record", as: :asset, dependent: :destroy
              has_one "asset_#{asset_class.asset_type}".to_sym, class_name: asset_class.name, as: :asset

              accepts_nested_attributes_for :asset_record

              AssetCore::Record.include Plugins::Models::Concerns::PolymorphicAlternative
              assoc_name = "asset_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::Entry.define_alternative_polyorphic_parent_association assoc: :asset, new_assoc: assoc_name, base_class: self.base_class

            end

            include InstanceMethods

          end

        end

        module InstanceMethods

          def asset
            @asset_proxy ||= AssetCore::Models::AssetProxy.new(self)
          end

          def asset_sync_data
            asset_record.sync_data if asset_record
          end

        end

        module SyncCallbacks
          extend ActiveSupport::Concern

          included do
            after_commit if: proc { |record| asset_config.sync != 'none' } do
              if asset_config.sync == 'sync'
                asset_sync_data
              elsif asset_entry_reference_config.sync == 'async'
                AssetCore::AssetWorker.perform_at(DateTime.now, nil, 'data_sync', *[self.class.name, self.id])
              end
            end
          end

        end

      end
    end
  end
end