module AssetCore
  module AssetScopes
    module Released

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :release do
        requires([:quantifiable_valuable])
        attributes(
          [
            release_method: {
              type: :string,
              validates: {
                inclusion: { in: :release_methods }
              }
            }
          ]
        )
        functions.setup(
          **{
            release_methods: proc {
              record&.release_methods || []
            }
          }
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :released do
        proxy "release"
        entry_scopes([:release])
        relationships.setup(
          ** {
            release_entry: [
              :has_one,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:release)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
            release_entries: [
              :has_many,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:release)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
          }
        )
        callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
        entry_callbacks.setup(
          **{
            before_validation: nil,
            validate: nil,
            after_validation: nil,
            before_save: nil,
            after_save: proc { |entry|
              if entry.state == "approved" && entry.saved_change_to_state?
                if asset
                  asset_state = entry.asset_ownership_states.new( record: self , index_name: "released", use_reference_data: true)
                  asset_state.save && asset_state.approve!
                end
              end
            },
          }
        )
        functions.setup(
          **{
            release_date: proc {
              release_entry&.date
            },
            release_value: proc {
              release_entry&.total_value
            },
            release_value_currency: proc {
              release_entry&.currency
            },
            release_method: proc {
              release_entry&.release_method
            },
            release_methods: proc {
              %w[sale donation scrap write_off returned_to_owner repossessed foreclosed]
            },
            gain_or_loss: proc {
              if release_method.present?
                if release_method == "sale"
                  carrying_value = (acquisition_value || 0) - (accrued_depreciation(release_date) || 0)
                  release_value - carrying_value
                else
                  accrued_depreciation(release_date) || acquisition_value || 0
                end
              end
            }
          },
        )
        entry_callbacks.setup(
          **{
            before_validation: nil,
            validate: proc { |entry|
              if entries.by_entry_scopes("release").where.not(id: entry.id).exists?
                entry.errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: proc { |entry|
              if entry.state == "approved" && entry.saved_change_to_state?
                if asset
                  asset_state = entry.asset_ownership_states.new( record: self , index_name: "released", use_reference_data: true)
                  asset_state.save && asset_state.approve!
                end
              end
            }
          }
        )
      end

    end
  end
end