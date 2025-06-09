module AssetCore
  module AssetScopes
    module Donation

      def self.scope_options
        {
          record_relationships: {
            has_one: [:donation_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:donation)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
          },
          entry_callbacks: {
            before_validation: nil,
            validate: nil,
            after_validation: nil,
            before_save: nil,
            after_save: proc {
              if state == "approved" && saved_change_to_state?
                if record && record.asset
                  asset_state = asset_ownership_states.new( record: record , index_name: "owned", use_reference_data: true)
                  asset_state.save
                end
              end
            },
          },
          entry_methods: {
            donation_date: proc {
              data.date
            },
            estimated_value: proc {
              data.estimated_value
            },
            donation_currency: proc {
              data.currency
            }
          },
          proxy_methods: {
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
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end