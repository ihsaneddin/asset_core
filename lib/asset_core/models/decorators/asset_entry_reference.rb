module AssetCore
  module Models
    module Decorators
      module AssetEntryReference

        def self.included(base)
          extend ClassMethods
        end

        def self.default_options
          {
            number: :id,
            description: nil,
            data: {},
            sync_data: 'none', # options are none, async, sync
          }
        end

        module ClassMethods

          def acts_as_asset_entry_reference *args, &block
            return unless ActiveRecord::Base.connection.table_exists?('asset_core_entries')
            opts = args.extract_options!
            opts = AssetCore::Models::Decorators::AssetEntryReference.default_options.merge(opts)

            ::Plugins::Models::Concerns::Config.setup(self, 'asset_entry_reference_config', opts, &block)

            unless reflect_on_association(:asset_entries)
              has_many :asset_entries, class_name: "AssetCore::Entry", as: :reference
              has_many :approved_entries, -> { where(state: 'approved').where.not(effective_at: nil) }, class_name: "AssetCore::Entry", as: :reference, extend: Extensions::DataSync

              AssetCore::Entry.subclasses.each do |sub|
                has_many "approved_#{sub.entry_name}_entries".to_sym, -> { where(state: 'approved').where.not(effective_at: nil) }, class_name: sub.name, as: :reference, extend: Extensions::DataSync
                has_one "approved_#{sub.entry_name}_entry".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at <= ?". DateTime.now).order(effective_at: :desc) }, class_name: sub.name, as: :reference, extend: Extensions::DataSync
                has_many "future_approved_#{sub.entry_name}_entries".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at > ?". DateTime.now) }, class_name: sub.name, as: :reference, extend: Extensions::DataSync
              end

              AssetCore::Entry.include Plugins::Models::Concerns::PolymorphicAlternative unless AssetCore::Entry.include?(Plugins::Models::Concerns::PolymorphicAlternative)
              assoc_name = "asset_entry_reference_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::Entry.define_alternative_polyorphic_parent_association assoc: :reference, new_assoc: assoc_name, base_class: self.base_class
            end

            include InstanceMethods unless include?(InstanceMethods)
            include SyncCallbacks unless include?(SyncCallbacks)

          end

        end

        module InstanceMethods

          def asset_entry_reference_config_data(*args)
            asset_entry_reference_config.data(*args)
          end

          def asset_entry_reference_sync_data
            AssetCore::Entry.subclasses.each do |sub|
              assoc = "approved_#{sub.entry_name}_entry".to_sym
              send(assoc).data_sync(self) if respond_to?(:assoc)
              assoc = "future_approved_#{sub.entry_name}_entries".to_sym
              send(assoc).data_sync(self) if respond_to?(assoc)
            end
          end

        end

        module SyncCallbacks
          extend ActiveSupport::Concern

          included do
            after_commit if: proc { |record| asset_entry_reference_config.sync != 'none' } do
              if asset_entry_reference_config.sync == 'sync'
                asset_entry_reference_sync_data
              elsif asset_entry_reference_config.sync == 'async'
                AssetCore::EntryReferenceWorker.perform_at(DateTime.now, nil, 'data_sync', *[self.class.name, self.id])
              end
            end
          end

        end

      end
    end
  end
end