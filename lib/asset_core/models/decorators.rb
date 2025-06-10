module AssetCore
  module Models
    module Decorators

      autoload :Asset, 'asset_core/models/decorators/asset'
      autoload :AssetEntryReference, 'asset_core/models/decorators/asset_entry_reference'
      autoload :AssetStateReference, 'asset_core/models/decorators/asset_state_reference'
      autoload :AssetScopes, 'asset_core/models/decorators/asset_scopes'
      autoload :AssetType, 'asset_core/models/decorators/asset_type'
      autoload :AssetCustodian, 'asset_core/models/decorators/asset_custodian'
      autoload :AssetOwner, 'asset_core/models/decorators/asset_owner'

    end
  end
end