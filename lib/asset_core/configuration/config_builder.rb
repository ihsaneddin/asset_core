module AssetCore
  module Configuration
    module ConfigBuilder

      def plugins_config
        ::Plugins::Models::Concerns::Config
      end

    end
  end
end