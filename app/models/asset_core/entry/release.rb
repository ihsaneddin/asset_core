module AssetCore
  class Entry::Release < AssetCore::Entry

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        data do
          {
            index: ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "released" },
            remark: description,
            custodian_name: nil,
            custodian_address: nil,
            start_date: date,
            end_date: nil
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
      attribute :release_method, :string
      attribute :reason, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :release

  end
end