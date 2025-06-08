module AssetCore
  class Entry::Purchase < AssetCore::Entry

    class Attributes < AssetCore::Attributes
      attribute :date, :date
      attribute :price, :decimal, default: 0.0
      attribute :currency, :string
      attribute :invoice_number, :string
      attribute :vendor_name, :string
      attribute :vendor_address, :string
      attribute :vendor_phone_number, :string

      validates :date, timeliness: { type: :date, allow_blank: true }
      validates :price, numericality: { greater_than: 0 }, allow_blank: true

    end

    custom_attributes_definition :data, ::AssetCore::Entry::Purchase::Attributes

    define_asset_scopes :acquisition, :purchase #do
    #   purchase do
    #     callbacks do
    #       after_save do
    #         if state == "approved" && saved_change_to_state?
    #           if record && record.asset
    #             asset_state = asset_ownership_states.new( record: record , index_name: "owned")
    #             unless asset_state.approved?
    #               asset_state.approve!
    #             end
    #           end
    #         end
    #       end
    #     end
    #     functions do
    #       purchase_value do
    #         data.price
    #       end
    #       purchase_currency do
    #         data.currency
    #       end
    #     end
    #   end
    # end
    #
    def self.after_engine_initialization
      asset_state_reference do
        index 0,
        data do
          {
            custodian_name: record.try(:asset).try(:owner).try(:name),
            custodian_address: record.try(:asset).try(:owner).try(:address),
            start_date: created_at,
            end_date: nil
          }
        end
      end
    end

  end
end