module AssetCore
  module AssetScopes
    module Donation

      def self.scope_options
        {
          record: {
            relationships: {
              donation_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:donation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
              donation_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:donation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            },
            callbacks: { before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil },
            functions: {
              donation_date: proc {
                donation_entry&.donation_date
              },
              estimated_value: proc {
                donation_entry&.estimated_value
              },
              donation_currency: proc {
                donation_entry&.estimated_value_currency
              }
            },
            entry_callbacks: {
              before_validation: nil, validate: nil, after_validation: nil, before_save: nil,
              after_save: proc {|entry|
                if entry.state == "approved" && entry.saved_change_to_state?
                  if asset
                    asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                    asset_state.save
                  end
                end
              }
            },
          },
          entry: {
            relationships: {},
            callbacks:  {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: nil,
            },
            functions: {
              donation_date: proc {
                data.date
              },
              estimated_value: proc {
                data.estimated_value
              },
              estimated_value_currency: proc {
                data.currency
              }
            }
          },
          proxy: {
            functions: {
              date: proc {
                record.donation_date
              },
              estimated_value: proc {
                purchase_entry&.estimated_value
              },
              estimated_value_currency: proc {
                purchase_entry&.estimated_value_currency
              }
            }
          }
        }
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end