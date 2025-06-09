module AssetCore
  module AssetScopes
    module Purchase

      def self.scope_options
        {
          record_relationships: {
            has_one: [:purchase_entry, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
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
            purchase_date: proc {
              data.date
            },
            purchase_value: proc {
              data.price
            },
            purchase_currency: proc {
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