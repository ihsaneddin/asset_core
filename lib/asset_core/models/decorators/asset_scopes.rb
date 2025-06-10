module AssetCore
  module Models
    module Decorators
      module AssetScopes

        def self.included base
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.include ::Plugins::Models::Concerns::Options::InheritableClassAttribute
          base.inheritable_class_attribute :asset_scopes
          base.extend ClassMethods
        end

        module ClassMethods

          def define_asset_scopes *args, &block
            return if args.blank?
            scopes = args.map(&:to_sym)
            scopes_config = ::AssetCore.config.asset_scopes.scopes.dup
            opts = {}
            base_key = self.base_class.name.demodulize.underscore.to_sym
            scopes.each do |scp|
              raise "Scope #{scp} not found" unless scopes_config.exists?(scp)
              cfg = scopes_config.send(scp).dup
              cfg.only_keys(base_key)
              opts[scp.to_sym] = cfg.send(base_key).dup
            end
            config = plugins_config.setup(self, 'asset_scopes_config', opts, opts.dup.slice(*scopes), &block)

            self.asset_scopes= config.values.keys.map(&:to_sym)

            self.asset_scopes.each do |asset_scope|
              ::AssetCore::AssetScopes.add_scoped_classes(asset_scope, self.name)
              if asset_scopes_config.send(asset_scope).exists?(:callbacks)
                asset_scopes_config.send(asset_scope).callbacks.values.each do |callback, v|
                  send callback do
                    asset_scopes_config.send(asset_scope).callbacks.send(callback)
                  end
                end
              end
              if asset_scopes_config.send(asset_scope).exists?(:functions)
                asset_scopes_config.send(asset_scope).functions.values.each do |funct, v|
                  define_method(funct) do |*args|
                    asset_scopes_config.send(asset_scope).functions.send(funct, *args)
                  end
                end
              end
              if asset_scopes_config.send(asset_scope).exists?(:relationships)
                asset_scopes_config.send(asset_scope).relationships.values.each do |rname, builder|
                  options = builder.extract_options!
                  relation = builder[0]
                  unless reflect_on_association(rname)
                    _scope = nil
                    _scope = builder[1] if builder[1].is_a?(Proc)
                    send(relation, rname, _scope, **options)
                  end
                end
              end
            end
          end

          def included_in_scopes?(*scopes)
            return if asset_scopes.nil?
            scopes.any? { |scp| asset_scopes.map(&:to_s).include?(scp.to_s)  }
          end

          def get_scoped_classes *scopes
            ::AssetCore::AssetScopes.get_scoped_classes(*scopes).select{|klass| klass.constantize.base_class == self.base_class }
          end

        end

        module EntryScopes
          extend ActiveSupport::Concern

          included do

            with_options if: :record do
              validate do
                unless (record.class.asset_scopes && self.class.asset_scopes).any?
                  errors.add(:invalid, :type)
                end
              end
              [:before_validation, :validate, :after_validation, :before_save, :after_save].each do |callback|
                send(callback) do
                  self.class.asset_scopes.each do |scp|
                    if record.class.asset_scopes.include?(scp)
                      if record.asset_scopes_config.send(scp)
                        record.asset_scopes_config.send(scp).entry_callbacks.send(callback, self)
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
end
