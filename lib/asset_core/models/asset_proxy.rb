module AssetCore
  module Models
    class AssetProxy

      attr_reader :asset, :record

      def self.setup(object)

        cfg = ::AssetCore::AssetScopes.scopes.dup
        scopes = object.record.class.asset_scopes

        opts = {}

        cfg.keys.select{|k| scopes.include?(k) }.each do |key|
          opts[key] = cfg.send(key).proxy.functions
        end

        cfg = cfg.class.new(values: opts)

        object.singleton_class.define_method :config do
          return @_asset_scopes if @_asset_scopes
          cfg.set_context(self)
          @_asset_scopes = cfg
          @_asset_scopes
        end

        cfg.keys.each do |key|
          object.singleton_class.define_method(key) do |*args|
            config.send(key, *args)
          end
        end

        ::AssetCore::State.descendants.each do |sub|

          object.singleton_class.define_method("#{sub.state_name}_state".to_sym) do
            record.send("current_#{sub.state_name}_state")
          end

          object.singleton_class.define_method("#{sub.state_name}_state_label".to_sym) do
            send("#{sub.state_name}_state").try(:state_label)
          end

          object.singleton_class.define_method("#{sub.state_name}_state_name".to_sym) do
            send("#{sub.state_name}_state").try(:state_name)
          end

          object.singleton_class.define_method("#{sub.state_name}_state_index".to_sym) do
            send("#{sub.state_name}_state").try(:index)
          end

          object.singleton_class.define_method("previous_#{sub.state_name}_state".to_sym) do
            send("#{sub.state_name}_state").try(:previous_state)
          end

          object.singleton_class.define_method("previous_#{sub.state_name}_state_label".to_sym) do
            send("previous_#{sub.state_name}_state").try(:state_label)
          end

          object.singleton_class.define_method("previous_#{sub.state_name}_state_name".to_sym) do
            send("previous_#{sub.state_name}_state").try(:state_name)
          end

          object.singleton_class.define_method("previous_#{sub.state_name}_state_index".to_sym) do
            send("previous_#{sub.state_name}_state").try(:index)
          end

        end
      end

      def initialize asset
        @asset = asset
        assoc = @asset.association(:asset_record)
        @record = assoc.reader if assoc.loaded?
        @record ||= assoc.target || assoc.build()
        self.class.setup(self)
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