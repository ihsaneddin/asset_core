module AssetCore
  class Entry::Purchase < AssetCore::Entry

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        index do
          ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "owned" }
        end
        remark :description
        data do
          {
            custodian_name: record&.asset&.owner&.try(:asset_owner_name),
            custodian_address: record&.asset&.owner&.try(:asset_owner_address),
            start_date: created_at || Date.today,
            end_date: nil
          }
        end
      end

      asset_entry_reference do
        number do
          SecureRandom.hex(8)
        end
        description :description
        data do
          {
            quantity: data.quantity
          }
        end
      end

    end


    class Attributes < AssetCore::Attributes

      attribute :date, :date
      attribute :value, :decimal, default: 0.0
      attribute :total_value, :decimal, default: 0.0
      attribute :quantity, :decimal, default: 1
      attribute :quantity_unit, :string
      attribute :currency, :string
      attribute :invoice_number, :string
      attribute :vendor_name, :string
      attribute :vendor_address, :string
      attribute :vendor_phone_number, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :acquisition, :purchase

  end
end