module AssetCore
  class Entry::Purchase < AssetCore::Entry

    custom_attributes_definition :data, Attributes

    asset_state_reference do
      data do
        {
          custodian_name: record.try(:asset).try(:owner).try(:name),
          custodian_address: record.try(:asset).try(:owner).try(:address),
          start_date: created_at,
          end_date: nil
        }
      end
    end

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

  end
end