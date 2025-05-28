module AssetCore
  module Configuration
    module Api

      include Plugins::Configuration::Api::Core

      self.authenticate = -> { User.first }

    end
  end
end