module AssetCore
  class Entry::Custody::Transfer < AssetCore::Entry::Custody

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        data do
          {
            index: record.current_ownership_state&.index || ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "owned" },
            remark: description,
            custodian_name: custodion_name,
            custodian_address: custodian_address
          }
        end
      end
    end

    class Attributes < ::AssetCore::Entry::Custody::Attributes

      attribute :custodian_name, :string
      attribute :custodian_address, :string
      attribute :custodian_contact, :string
      attribute :custodian_organization_name, :string
      attribute :notes, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :custody_transfer

  end
end