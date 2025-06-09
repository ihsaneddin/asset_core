module AssetCore
  class Entry::Donation < AssetCore::Entry

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        index do
          ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "owned" }
        end
        remark :description
        data do
          {
            custodian_name: record.asset.owner.try(:asset_owner_name),
            custodian_address: record.asset.owner.try(:asset_owner_address),
            start_date: created_at || Date.today,
            end_date: nil
          }
        end
      end
    end

    class Attributes < ::AssetCore::Attributes

      attribute :date, :date
      attribute :donor_name, :string
      attribute :estimated_value, :decimal, default: 0.0
      attribute :currency, :string
      attribute :notes, :string

      before_validation do
        self.date ||= Date.today
        self.estimated_value ||= 0
      end

      validates :date, timeliness: { type: :date }, if: :date
      validates :donor_name, presence: true
      validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }

      before_validation do
        self.donor_name ||= "Anonymous"
      end
    end

    custom_attributes_definition :data, Attributes

    define_asset_scopes :acquisition do
      acquisition do
        entry_methods do
          acquisition_value do
            data.estimated_value
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