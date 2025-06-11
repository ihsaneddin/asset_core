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
      attribute :price, :decimal, default: 0.0
      attribute :currency, :string
      attribute :invoice_number, :string
      attribute :vendor_name, :string
      attribute :vendor_address, :string
      attribute :vendor_phone_number, :string
      attribute :quantity, :decimal, default: 1
      attribute :quantity_unit, :string, default: "piece"
      attribute :unit_price, default: 0

      before_validation do
        self.date ||= Date.today
      end

      after_validation do
        if price
          self.unit_price ||= price / quantity
        end
      end

      validates :date, timeliness: { type: :date }
      validates :price, numericality: { greater_than: 0 }, allow_blank: true
      validates :quantity, numericality: { greater_than: 0 }
      validates :quantity_unit, presence: true

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :acquisition, :purchase do
      acquisition do
        functions do
          acquisition_value do
            data.price
          end
          acquisition_value_currency do
            data.currency
          end
          acquisition_date do
            data.date
          end
        end
      end
    end

  end
end