module AssetCore
  module Models
    module Decorators
      module AssetRecodScopes

        mattr_accessor :record_scopes_classes
        @@record_scopes_classes = []

        def self.get_record_class_with_scopes key, klass
          @@record_scopes_classes[scope.to_sym] ||= []
          @@record_scopes_classes[scope.to_sym] << klass
        end

        def self.get_record_class_with_scopes *_scopes
          _scopes.inject([]) do |arr, scope|
            arr + @@record_scopes_classes[scope.to_sym] || []
          end
        end

        def self.included base
          base.extend ::AssetCore::Configuration::ConfigBuilder
          base.include ::Plugins::Models::Concerns::Options::InheritableClassAttribute
          base.inheritable_class_attribute :asset_record_scopes
          base.extend ClassMethods
        end

        module ClassMethods

          def define_asset_record_scopes *args, &block
            return if args.blank?
            scopes = args.map(&:to_sym)
            scopes_config = ::AssetCore.config.asset_record_scopes.record_scopes.dup
            opts = {}
            scopes.each do |scp|
              raise "Scope #{scp} not found" unless scopes_config.exists?(scp)
              cfg = scopes_config.send(scp).dup
              opts[scp.to_sym] = cfg.dup
            end
            config = plugins_config.setup(self, 'asset_record_scopes_config', opts, opts.dup.slice(*scopes), &block)

            self.asset_record_scopes= config.values.keys.map(&:to_sym)

            self.asset_record_scopes.each do |asset_scope|
              ::AssetCore::Models::Decorators:AssetRecodScopes.add_record_class_to_scope(asset_scope, self.name)
              if asset_record_scopes_config.send(asset_scope).exists?(:callbacks)
                asset_record_scopes_config.send(asset_scope).callbacks.values.each do |callback, v|
                  send callback do
                    asset_record_scopes_config.send(asset_scope).callbacks.send(callback)
                  end
                end
              end
              if asset_record_scopes_config.send(asset_scope).exists?(:functions)
                asset_record_scopes_config.send(asset_scope).functions.values.each do |funct, v|
                  unless method_defined?(funct)
                    define_method(funct) do |*args|
                      asset_record_scopes_config.send(asset_scope).functions.send(funct, *args)
                    end
                  end
                end
              end
              if asset_record_scopes_config.send(asset_scope).exists?(:relationships)
                asset_record_scopes_config.send(asset_scope).relationships.values.each do |rname, builder|
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
            return if asset_record_scopes.nil?
            scopes.any? { |scp| asset_record_scopes.map(&:to_s).include?(scp.to_s)  }
          end

          def get_classes_with_scopes *scopes
            ::AssetCore::Models::Decorators:AssetRecodScopes.get_record_class_with_scopes(*scopes).select{|klass| klass.constantize.base_class == self.base_class }
          end

        end

        module InstanceMethods

          def entries_scopes
            asset_record_scopes_config.values.inject([]) do |arr, (record_scope, config)|
              arr << config.entry_scopes
            end.flatten
          end

          def entries_callbacks_for_scope scope
            result = asset_record_scopes_config.values.inject([]) do |arr, (record_scope, config)|
              scopes = config.entry_scopes
              scopes = [scopes] unless scopes.is_a?(Array)
              if scopes.map(&:to_s).include?(scope.to_s)
                arr << config.entry_callbacks
              end
            end
            result
          end

        end

      end
    end
  end
end
