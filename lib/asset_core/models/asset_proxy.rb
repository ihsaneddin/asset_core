module AssetCore
  module Models
    class AssetProxy

      attr_reader :asset, :record

      def self.setup_asset_scopes_proxy_methods

        cfg = ::AssetCore::AssetScopes.scopes.dup
        opts = {}
        cfg.keys.each do |key|
          opts[key] = cfg.send(key).proxy_methods.dup
        end

        cfg = cfg.class.new(values: opts)

        define_method :config do
          return @_asset_scopes if @_asset_scopes
          cfg.set_context(self)
          @_asset_scopes = cfg
          @_asset_scopes
        end

        cfg.keys.each do |key|
          define_method(key) do
            config.send(key)
          end
        end

        ::AssetCore::State.descendants.each do |sub|

          define_method("#{sub.state_name}_state".to_sym) do
            record.send("current_#{sub.state_name}_state").try(:state_label)
          end

          define_method("#{sub.state_name}_state_label".to_sym) do
            send("current_#{sub.state_name}_state").try(:state_label)
          end

          define_method("#{sub.state_name}_state_name".to_sym) do
            send("current_#{sub.state_name}_state").try(:state_name)
          end

          define_method("#{sub.state_name}_state_index".to_sym) do
            send("current_#{sub.state_name}_state").try(:index)
          end

          define_method("previous_#{sub.state_name}_state_label".to_sym) do
            record.send("current_#{sub.state_name}_state").try(:previous_state)
          end

          define_method("previous_#{sub.state_name}_state_label".to_sym) do
            send("previous_#{sub.state_name}_state").try(:state_label)
          end

          define_method("previous_#{sub.state_name}_state_name".to_sym) do
            send("previous_#{sub.state_name}_state").try(:state_name)
          end

          define_method("previous_#{sub.state_name}_state_index".to_sym) do
            send("previous_#{sub.state_name}_state").try(:index)
          end

        end
      end

      def initialize asset
        self.class.setup_asset_scopes_proxy_methods
        @asset = asset
        assoc = @asset.association(:asset_record)
        @record = assoc.reader if assoc.loaded?
        @record ||= assoc.target || assoc.build()
      end

      def record
        @record
      end

      def asset
        @asset
      end

    end
  end
end