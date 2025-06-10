module AssetCore
  module AssetScopes
    module Purchase

      def self.scope_options
        {
          record: {
            relationships: {
              purchase_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
              purchase_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            },
            callbacks: {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: nil,
            },
            functions: {
              purchase_date: proc {
                purchase_entry&.purchase_date
              },
              purchase_value: proc {
                purchase_entry&.purchase_price
              },
              purchase_currency: proc {
                purchase_entry&.purchase_price_currency
              }
            },
            entry_callbacks: {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: proc { |entry|
                if entry.state == "approved" && entry.saved_change_to_state?
                  if asset
                    asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                    asset_state.save
                  end
                end
              },
            }
          },
          entry: {
            relationships: {},
            callbacks: {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: nil
            },
            functions: {
              purchase_date: proc {
                data.date
              },
              purchase_value: proc {
                data.price
              },
              purchase_currency: proc {
                data.currency
              }
            }
          },
          proxy: {
            functions: {
              value: proc {
                purchase_entry&.purchase_value
              },
              currency: proc {
                purchase_entry&.purchase_currency
              },
              date: proc {
                purchase_entry&.purchase_date
              }
            }
          }
        }
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end