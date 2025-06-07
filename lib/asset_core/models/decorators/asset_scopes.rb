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
            scopes.each do |scp|
              raise "Scope #{scp} not found" unless scopes_config.exists?(scp)
              cfg = scopes_config.send(scp).dup
              opts[scp.to_sym] = cfg
            end

            config = plugins_config.setup(self, 'asset_scopes_config', opts, &block)

            self.asset_scopes= config.values.keys.map(&:to_sym)

            self.asset_scopes.each do |asset_scope|
              asset_scopes_config.send(asset_scope).callbacks.values.each do |callback, v|
                send callback do
                  asset_scopes_config.callbacks.send(callback)
                end
              end
              asset_scopes_config.send(asset_scope).functions.values.each do |funct, v|
                define_method(funct) do
                  asset_scopes_config.functions.send(funct)
                end
              end
            end

          end

          def included_in_scopes(*scopes)
            return asset_scopes.nil?
            scopes.any? { |scp| asset_scopes.map(&:to_s).include?(scp.to_s)  }
          end

        end

      end
    end
  end
end
