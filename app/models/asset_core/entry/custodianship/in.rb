module AssetCore
  class Entry::Custody::In < AssetCore::Entry::Custody

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        data do
          {
            index: ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "custody_in" },
            remark: description,
            custodian_name: record&.asset&.owner&.try(:asset_owner_name),
            custodian_address: record&.asset&.owner&.try(:asset_owner_address),
            custodian_contact: record&.asset&.owner&.try(:asset_owner_contact),
            counterparty_name: owner_name,
            counterparty_address:  owner_address,
            counterparty_contact: owner_contact
          }
        end
      end
    end

    class Attributes < ::AssetCore::Entry::Custody::Attributes

      attribute :owner_name, :string
      attribute :owner_address, :string
      attribute :owner_contact, :string
      attribute :owner_organization_name, :string
      attribute :custody_type, :string

    end

    custom_attributes_definition :data, ::AssetCore::Entry::Custody::In::Attributes, accessor: true

    define_asset_entry_scopes :acquisition, :custody_in, :quantifiable_valuable

  end
end