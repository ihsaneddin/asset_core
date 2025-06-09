module AssetCore
  module AssetScopes
    module Release

      def self.scope_options
        {
          record_relationships: {
            has_one: [
              :release_entry,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:release)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
          },
          entry_callbacks: {
            before_validation: nil,
            validate: proc {
              if record.entries.by_entry_scopes("release").where.not(id: id).exists?
                errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: proc {
              if state == "approved" && saved_change_to_state?
                if record && record.asset
                  asset_state = asset_ownership_states.new( record: record , index_name: "released", use_reference_data: true)
                  asset_state.save && asset_state.approve!
                end
              end
            },
          },
          entry_methods: {
            release_date: proc {
              data.date
            },
            release_value: proc {
              data.release_value || 0
            },
            release_value_currency: proc {
              data.release_value_currency
            },
            release_method: proc {
              data.release_method
            },
            gain_or_loss?: proc {
              if release_method == "sale"
                carrying_value = (record.acquisition_entry&.acquisition_value || 0) - (record.depreciation_entry&.accrued_depreciation(release_date) || 0)
                release_value - carrying_value
              else
                record.depreciation_entry&.accrued_depreciation(release_date) || record.acquisition_entry&.acquisition_value || 0
              end
            }
          },
          proxy_methods: {
            date: proc {
              record.release_entry&.release_date
            },
            value: proc {
              record.release_entry&.release_value
            },
            value_currency: proc {
              record.release_entry&.release_value_currency
            },
            release_method: proc {
              record.release_entry&.release_method
            },
            gain_or_loss?: proc {
              record.release_entry&.gain_or_loss
            }
          }
        }
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end