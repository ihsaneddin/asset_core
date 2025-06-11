module AssetCore
  module Models
    module Decorators
      module AssetStateReference

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
            index: nil,
            remark: nil,
            data: {},
            sync_data: 'none', # options are none, async, syncsync_data
          }
        end

        module ClassMethods

          def asset_state_reference **opts, &block
            return unless ActiveRecord::Base.connection.table_exists?('asset_core_states')
            default_opts = AssetCore::Models::Decorators::AssetStateReference.default_options

            plugins_config.setup(self, 'asset_state_reference_config', opts, default_opts, &block)
            unless reflect_on_association(:asset_states)
              has_many :asset_states, class_name: "AssetCore::State", as: :reference
              has_many :current_states, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at <= ?". DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::State", as: :reference

              accepts_nested_attributes_for :asset_states, allow_destroy: true

              AssetCore::State.subclasses.each do |sub|
                define_state_subclass_relation(sub)
              end

              AssetCore::State.include Plugins::Models::Concerns::PolymorphicAlternative unless AssetCore::State.include?(Plugins::Models::Concerns::PolymorphicAlternative)
              assoc_name = "asset_state_reference_of_#{self.base_class.name.demodulize.underscore}"
              AssetCore::State.define_alternative_polymorphic_parent_association assoc: :reference, new_assoc: assoc_name, base_class: self.base_class
            end

            include InstanceMethods unless include?(InstanceMethods)
            include SyncCallbacks unless include?(SyncCallbacks)

            ::AssetCore::Models::Decorators::AssetEntryReference << self

          end

          def define_state_subclass_relation sub
            unless reflect_on_association("asset_#{sub.state_name}_states".to_sym)
              has_many "asset_#{sub.state_name}_states".to_sym, class_name: sub.name, as: :reference
              accepts_nested_attributes_for "asset_#{sub.state_name}_states".to_sym, allow_destroy: true
            end
            unless reflect_on_association("current_asset_#{sub.state_name}_state".to_sym)
              has_one "current_asset_#{sub.state_name}_state".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at <= ?". DateTime.now).order(effective_at: :desc) }, class_name: sub.name, as: :reference
            end
            unless reflect_on_association("future_asset_#{sub.state_name}_states".to_sym)
              has_many "future_asset_#{sub.state_name}_states".to_sym, -> { where(state: 'approved').where.not(effective_at: nil).where("effective_at > ?". DateTime.now) }, class_name: sub.name, as: :reference
            end
          end

        end

        module InstanceMethods

          def asset_state_reference_config_data(*args)
            asset_state_reference_config.data(*args)
          end

        end

        module SyncCallbacks
          extend ActiveSupport::Concern

          included do

            attr_accessor :asset_state_data

            after_initialize :set_asset_state_data

            after_commit if: :asset_state_data_changes? do
              if asset_state_reference_config.sync_data == 'sync'
                sync_asset_states
              elsif asset_state_reference_config.sync_data == 'async'
                AssetCore::StateReferenceWorker.perform_at(DateTime.now, nil, 'data_sync', *[self.class.name, self.id])
              end
              set_asset_state_data
            end
          end

          def set_asset_state_data
            self.asset_state_data = {
              index: asset_state_reference_config_index,
              remark: asset_state_reference_config_remark,
              data: asset_state_reference_config_data
            }
          end

          def asset_state_data_changes?
            current_asset_state_data = {
              index: asset_state_reference_config_index,
              remark: asset_state_reference_config_remark,
              data: asset_state_reference_config_data
            }
            !(Hashdiff.diff(current_asset_state_data, asset_state_data).empty?)
          end

          def sync_asset_states
            asset_states.where(use_reference_data: true).each do |stat|
              stat.attributes_use_asset_state_reference!
            end
          end

        end

      end
    end
  end
end