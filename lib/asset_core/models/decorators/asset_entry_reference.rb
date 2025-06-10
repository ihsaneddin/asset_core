module AssetCore
  module Models
    module Decorators
      module AssetEntryReference

        mattr_accessor :reference_classes
        @@reference_classes = []

        def self.<< klass
          @@reference_classes << klass
        end

        def self.included(base)
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.extend ClassMethods
        end

        def self.default_options
          {
            number: nil,
            description: nil,
            data: {},
            sync_data: 'none', # options are none, async, sync
          }
        end

        module ClassMethods

          def asset_entry_reference **opts, &block
            return unless ActiveRecord::Base.connection.table_exists?('asset_core_entries')
            default_opts = AssetCore::Models::Decorators::AssetEntryReference.default_options

            # ::Plugins::Models::Concerns::Config.setup(self, 'asset_entry_reference_config', opts, &block)
            plugins_config.setup(self, 'asset_entry_reference_config', opts, default_opts, &block)

            unless reflect_on_association(:asset_entries)
              has_many :asset_entries, class_name: "AssetCore::Entry", as: :reference

              accepts_nested_attributes_for :asset_entries, allow_destroy: true

              AssetCore::Entry.include Plugins::Models::Concerns::PolymorphicAlternative unless AssetCore::Entry.include?(Plugins::Models::Concerns::PolymorphicAlternative)
              assoc_name = "asset_entry_reference_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::Entry.define_alternative_polymorphic_parent_association assoc: :reference, new_assoc: assoc_name, base_class: self.base_class
            end

            AssetCore::Entry.subclasses.each do |sub|
              define_entry_subclass_relation sub
            end

            include InstanceMethods unless include?(InstanceMethods)
            include SyncCallbacks unless include?(SyncCallbacks)

            ::AssetCore::Models::Decorators::AssetEntryReference << self

          end

          def define_entry_subclass_relation sub
            unless reflect_on_association("asset_#{sub.entry_name}_entries".to_sym)
              has_many "asset_#{sub.entry_name}_entries".to_sym, class_name: sub.name, as: :reference
              accepts_nested_attributes_for "asset_#{sub.entry_name}_entries".to_sym, allow_destroy: true
            end
            unless reflect_on_association("current_asset_#{sub.entry_name}_entry".to_sym)
              has_one "current_asset_#{sub.entry_name}_entry".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at <= ?". DateTime.now).order(effective_at: :desc) }, class_name: sub.name, as: :reference
            end
            unless reflect_on_association("future_asset_#{sub.entry_name}_entries".to_sym)
              has_many "future_asset_#{sub.entry_name}_entries".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at > ?". DateTime.now) }, class_name: sub.name, as: :reference
            end
          end

        end

        module InstanceMethods

          def asset_entry_reference_config_data(*args)
            asset_entry_reference_config.data(*args)
          end

        end

        module SyncCallbacks
          extend ActiveSupport::Concern

          included do

            attr_accessor :asset_entry_data

            after_initialize :set_asset_entry_data
            after_save :set_asset_entry_data

            after_commit if: :asset_entry_data_changes? do
              if asset_entry_reference_config.sync_data == 'sync'
                sync_asset_entries
              elsif asset_entry_reference_config.sync_data == 'async'
                AssetCore::EntryReferenceWorker.perform_at(DateTime.now, nil, 'data_sync', *[self.class.name, self.id])
              end
            end
          end

          def set_asset_entry_data
            self.asset_entry_data = {
              number: asset_entry_reference_config_number,
              description: asset_entry_reference_config_description,
              data: asset_entry_reference_config_data
            }
          end

          def asset_entry_data_changes?
            current_asset_entry_data = {
              number: asset_entry_reference_config_number,
              description: asset_entry_reference_config_description,
              data: asset_entry_reference_config_data
            }
            !(Hashdiff.diff(current_asset_entry_data, asset_entry_data).empty?)
          end

          def sync_asset_entries
            asset_entries.where(use_reference_data: true).each do |entry|
              entry.attributes_use_asset_entry_reference!
            end
          end

        end

      end
    end
  end
end