module AssetCore
  module AssetScopes
    module Acquisited

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :acquisition do
        requires([:quantifiable, :valuable])
        functions.setup(
          **{
            acquisition_method: proc {
              self.class.entry_name
            },
          }
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :acquisited do
        proxy "acquisition"
        entry_scopes([:acquisition])
        relationships.setup(
          **{
            acquisition_entry: [
              :has_one,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
            acquisition_entries: [
              :has_many,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
          }
        )
        callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
        functions.setup(
          **{
            acquisition_value: proc {
              acquisition_entry&.value
            },
            acquisition_total_value: proc {
              acquisition_entry&.total_value
            },
            acquisition_value_currency: proc {
              acquisition_entry&.currency
            },
            acquisition_date: proc {
              acquisition_entry&.date
            },
            acquisition_method: proc {
              acquisition_entry&.acquisition_method
            },
            acquisition_quantity: proc {
              acquisition_entry&.quantity
            },
            acquisition_quantity_unit: proc {
              acquisition_entry&.quantity_unit
            },
          }
        )
        entry_callbacks.setup(
          **{
            before_validation: nil,
            validate: nil,
            after_validation: nil,
            before_save: nil,
            after_save: nil
          }
        )
      end

    end
  end
end
