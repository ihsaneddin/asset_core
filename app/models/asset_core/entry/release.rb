module AssetCore
  class Entry::Release < AssetCore::Entry

    include ::Plugins::EngineCallbacks
    after_asset_core_initialization do
      asset_state_reference do
        index do
          ::AssetCore::State::Ownership.states_list.index{ |state| state[:name] == "released" }
        end
        remark :description
        data do
          {
            custodian_name: nil,
            custodian_address: nil,
            start_date: data.date,
            end_date: nil
          }
        end
      end
    end

    class Attributes < AssetCore::Attributes

      attribute :date, :date
      attribute :release_method, :string
      attribute :release_value, :decimal, default: 0.0
      attribute :currency, :string
      attribute :reason, :string

      before_validation do
        self.release_method ||= "sale"
        self.release_value ||= 0
        self.date ||= Date.today
      end

      validates :date, timeliness: { type: :date }, allow_blank: true
      validates :release_method, presence: true, inclusion: { in: %w[sale donation scrap write_off] }
      validates :release_value, numericality: { greater_than_or_equal_to: 0 }, if: :sold?

      def sold?
        release_method == "sale"
      end

    end

    custom_attributes_definition :data, Attributes

    define_asset_scopes :release

  end
end