module AssetCore
  module AssetScopes
    module Donatable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :donation do
        requires([:quantifiable_valuable])
        attributes(
          [
            :notes,
            date: {
              type: :date,
              validates: {
                timeliness: {type: :date}
              }
            },
            donor_name: {
              type: :string,
              default: "Anonymous",
            }
          ]
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :donated do
        proxy "donation"
        entry_scopes([:donation])
        relationships.setup(
          **{
            donation_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:donation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            donation_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:donation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
          }
        )
        callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
        entry_callbacks.setup(
          **{
            before_validation: nil, validate: nil, after_validation: nil, before_save: nil,
            after_save: proc {|entry|
              if entry.state == "approved" && entry.saved_change_to_state?
                if asset
                  asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                  asset_state.save
                end
              end
            }
          }
        )
        functions.setup(
          ** {
            donation_date: proc {
              donation_entry&.date
            },
            donation_estimated_value: proc {
              donation_entry&.total_value
            },
            donation_currency: proc {
              donation_entry&.currency
            }
          }
        )
      end

    end
  end
end