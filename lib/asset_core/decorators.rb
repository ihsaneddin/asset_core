module AssetCore
  module Decorators

    def self.asset
      ::AssetCore::Models::Decorators::Asset
    end

    def self.asset_methods
      asset::InstanceMethods
    end

    def self.asset_entry_reference
      ::AssetCore::Models::Decorators::AssetEntryReference
    end

    def self.asset_entry_reference_methods
      asset_entry_reference::InstanceMethods
    end

    def self.asset_state_reference
      ::AssetCore::Models::Decorators::AssetStateReference
    end

    def self.asset_state_reference_methods
      asset_state_reference::InstanceMethods
    end

    def self.asset_owner
      ::AssetCore::Models::Decorators::AssetOwner
    end

    def self.asset_owner_methods
      asset_owner::InstanceMethods
    end

    def self.asset_custodian
      ::AssetCore::Models::Decorators::AssetCustodian
    end

    def self.asset_custodian_methods
      asset_custodian::InstanceMethods
    end

    def self.asset_record_scopes
      ::AssetCore::Models::Decorators::AssetRecordScopes
    end

    def self.asset_entry_scopes
      ::AssetCore::Models::Decorators::AssetEntryScopes
    end

    def self.asset_entry_type
      ::AssetCore::Models::Decorators::AssetType
    end

  end
end