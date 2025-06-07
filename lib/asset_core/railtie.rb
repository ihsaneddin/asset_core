require 'rails/railtie'

module AssetCore
  class Railtie < ::Rails::Railtie

    initializer 'asset_core.initialize' do
      ActiveSupport.on_load(:active_record) do
        include ::AssetCore.decorators.asset_owner
        include ::AssetCore.decorators.asset_custodian
        include ::AssetCore.decorators.asset
        include ::AssetCore.decorators.asset_entry_reference
        include ::AssetCore.decorators.asset_state_reference
      end
    end

  end
end