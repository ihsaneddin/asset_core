module AssetCore
  module AssetScopes
    module Entry

      DEFAULT_SCOPES = [:acquisition, :purchase, :donation, :depreciation]
      DEFAULT_SCOPES.each do |scope|
        autoload scope.to_s.classify.to_sym, "asset_core/models/decorators/scopes/entry/#{scope}"
      end

      def self.extended base
        if base.is_a?(Module)
          ::AssetCore::AssetScopes.add_entry_scope(base.name.demodulize.underscore.to_sym, base)
        end
      end

      def self.scope_name
        name.demodulize.underscore.to_sym
      end

      def self.model_options
        {
          before_validation: nil,
          validation: nil,
          after_validation: nil,
          before_save: nil,
          after_save: nil,
          guard_approve: nil,
          before_approve: nil,
          after_approve: nil,
          guard_reject: nil,
          before_reject: nil,
          after_reject: nil,
        }
      end

      def self.proxy_options(_scope_name= scope_name)
        {
          collection: proc { |record|
            record.entries.approved.by_entry_scopes(_scope_name)
          },
          functions: ::Plugins::Models::Config.new({})
        }
      end

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods

        def used_as_asset_scope_of *args, &block

        end

      end

    end
  end
end