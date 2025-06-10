module AssetCore
  module Models
    module Decorators
      module AssetType

        def self.included base
          base.include ::Plugins::Models::Concerns::Options::InheritableClassAttribute
          base.inheritable_class_attribute :asset_type
          base.extend ClassMethods
        end

        module ClassMethods

          def define_asset_type *args, &block
            opts = args.extract_options!
            _type = args[0] || self.name.demodulize.underscore.to_sym

            scopes = opts[:scopes] || []

            self.asset_type= _type.to_sym

            include(::AssetCore.decorators.asset_scopes) unless include?(::AssetCore.decorators.asset_scopes)

            define_asset_scopes(*scopes, &block)

          end

          def included_in_type?(*types)
            return if asset_type.nil?
            types.map(&:to_s).include?(asset_type.to_s)
          end

          def find_by_asset_type(type)
            self.base_class.descendants.select{|sub| sub.asset_type.to_s == type.to_s }[0]
          end

        end

      end
    end
  end
end
