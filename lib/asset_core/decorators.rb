module AssetCore
  module Decorators

    def asset
      ::AssetCore::Models::Decorators::Asset
    end

    def asset_methods
      asset::InstanceMethods
    end

    def asset_entry_reference
      ::AssetCore::Models::Decorators::AssetEntryReference
    end

    def asset_entry_reference_methods
      asset_entry_reference::InstanceMethods
    end

    def asset_state_reference
      ::AssetCore::Models::Decorators::AssetStateReference
    end

    def asset_state_reference
      asset_state_reference::InstanceMethods
    end

  end
end