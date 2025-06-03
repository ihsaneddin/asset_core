module AssetCore
  class Entry::Donation < AssetCore::Entry

    custom_attributes_definition :data, Attributes

    asset_state_reference do
      description :description
      data do
        {
          custodian_name: record.try(:asset).try(:owner).try(:name),
          custodian_address: record.try(:asset).try(:owner).try(:address),
          start_date: nil,
          end_date: nil
        }
      end
    end

    def after_entry_is_approved
      asset_state = asset_purchase_states.create( record: record, index_name: "owned" )
      unless asset_state.approved?
        asset_state.approve!
      end
    end

    def after_entry_is_rejected

    end

  end
end