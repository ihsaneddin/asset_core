module AssetCore
  class Entry::Donation < AssetCore::Entry

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        data do
          {
            index: ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "owned" },
            remark: description,
            custodian_name: record.asset.owner.try(:asset_owner_name),
            custodian_address: record.asset.owner.try(:asset_owner_address),
          }
        end
      end
    end

    class Attributes < ::AssetCore::Attributes

      attribute :date, :date
      attribute :value, :decimal, default: 0.0
      attribute :total_value, :decimal, default: 0.0
      attribute :quantity, :decimal, default: 1
      attribute :quantity_unit, :string, default: "piece"
      attribute :currency, :string
      attribute :donor_name, :string
      attribute :notes, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :acquisition, :donation

  end
end