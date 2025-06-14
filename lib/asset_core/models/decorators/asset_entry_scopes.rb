module AssetCore
  module Models
    module Decorators
      module AssetEntryScopes

        mattr_accessor :entry_scopes_classes
        @@entry_scopes_classes = {}

        def self.add_entry_class_to_scope key, klass
          @@entry_scopes_classes[key.to_sym] ||= []
          @@entry_scopes_classes[key.to_sym] << klass
        end

        def self.get_entry_class_with_scopes *_scopes
          _scopes.inject([]) do |arr, scope|
            arr + @@entry_scopes_classes[scope.to_sym] || []
          end
        end

        def self.included base
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.include ::Plugins::Models::Concerns::Options::InheritableClassAttribute
          base.inheritable_class_attribute :asset_entry_scopes
          base.extend ClassMethods
          base.scope :with_entry_scopes, -> (*scopes) {
            base_class.where(type: get_classes_with_scopes(*scopes))
          }
        end

        module ClassMethods

          def set_asset_entry_scopes_opts *scopes
            scopes_config = ::AssetCore.config.asset_scopes.entry_scopes.dup
            opts = {}
            scopes.each do |scp|
              raise "Scope #{scp} not found" unless scopes_config.exists?(scp)
              cfg = scopes_config.send(scp).dup
              opts[scp.to_sym] = cfg.dup
              unless cfg.requires.empty?
                opts = opts.merge(set_asset_entry_scopes_opts(*cfg.requires))
              end
            end
            opts
          end

          def define_asset_entry_scopes *args, &block
            return if args.blank?
            scopes = args.map(&:to_sym)
            opts = set_asset_entry_scopes_opts(*scopes)
            scopes = opts.keys
            config = plugins_config.setup(self, 'asset_entry_scopes_config', opts, opts.dup.slice(*scopes), &block)

            self.asset_entry_scopes= config.values.keys.map(&:to_sym)
            self.asset_entry_scopes.each do |asset_scope|
              ::AssetCore::Models::Decorators::AssetEntryScopes.add_entry_class_to_scope(asset_scope, self.name)

              if asset_entry_scopes_config.send(asset_scope).exists?(:callbacks)
                asset_entry_scopes_config.send(asset_scope).callbacks.values.each do |callback, v|
                  send callback do
                    asset_entry_scopes_config.send(asset_scope).callbacks.send(callback)
                  end
                end
              end
              if asset_entry_scopes_config.send(asset_scope).exists?(:functions)
                asset_entry_scopes_config.send(asset_scope).functions.values.each do |funct, v|
                  unless method_defined?(funct)
                    if v.arity > 0
                      define_method(funct) do |*args|
                        asset_entry_scopes_config.send(asset_scope).functions.send(funct, *args)
                      end
                    else
                      define_method(funct) do
                        asset_entry_scopes_config.send(asset_scope).functions.send(funct)
                      end
                    end
                  end
                end
              end
              if asset_entry_scopes_config.send(asset_scope).exists?(:relationships)
                asset_entry_scopes_config.send(asset_scope).relationships.values.each do |rname, builder|
                  options = builder.extract_options!
                  relation = builder[0]
                  unless reflect_on_association(rname)
                    _scope = nil
                    _scope = builder[1] if builder[1].is_a?(Proc)
                    send(relation, rname, _scope, **options)
                    accepts_nested_attributes_for relation, allow_destroy: true, reject_if: :allow_blank
                  end
                end
              end
              if asset_entry_scopes_config.send(asset_scope).exists?(:attributes)
                asset_entry_scopes_config.send(asset_scope).attributes.each do |att|
                  if att.is_a?(Hash)
                    att.each do |k, opts|
                      att_name = k
                      att_type = opts.delete(:type) || :string
                      validation = opts.delete(:validates) || {}
                      unless attribute_types.key?(k.to_s)
                        attribute(att_name, att_type, **opts)
                      end
                      validates(k, **validation) unless validation.empty?
                    end
                  elsif att.is_a?(String) || att.is_a?(Symbol)
                    unless attribute_types.key?(att.to_s)
                      attribute att, :string
                    end
                  end
                end
              end
            end

            include(AssetEntryScopesCallbacks) unless include?(AssetEntryScopesCallbacks)
          end

          def included_in_scopes?(*scopes)
            return if asset_entry_scopes.nil?
            scopes.any? { |scp| asset_entry_scopes.map(&:to_s).include?(scp.to_s)  }
          end

          def get_classes_with_scopes *scopes
            ::AssetCore::Models::Decorators::AssetEntryScopes.get_entry_class_with_scopes(*scopes)#.select{|klass| klass.constantize.base_class == self.base_class }
          end

        end

        module AssetEntryScopesCallbacks
          extend ActiveSupport::Concern

          included do

            with_options if: :record do
              validate do
                unless (record.entries_scopes.map(&:to_s) && self.class.asset_entry_scopes.map(&:to_s)).any?
                  errors.add(:type, :invalid)
                end
              end
              [:before_validation, :validate, :after_validation, :before_save, :after_save].each do |callback|
                send(callback) do
                  self.class.asset_entry_scopes.each do |scp|
                    record.entries_callbacks_for_scope(scp).each do |entry_callback|
                      entry_callback.send(callback, self) if entry_callback.exists?(callback)
                    end
                  end
                end
              end

            end
          end

        end

      end
    end
  end
end
