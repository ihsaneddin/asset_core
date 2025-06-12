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
            validate: proc { |entry|
              if entries.by_entry_scopes("acquisition").where.not(id: entry.id).exists?
                entry.errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: nil
          }
        )
      end

      def self.scope_options
        {
          record: {
            relationships: {
              acquisition_entry: [
                :has_one,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
              acquisition_entries: [
                :has_many,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
            },
            callbacks: { before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil },
            functions: {
              acquisition_value: proc {
                acquisition_entry&.acquisition_value
              },
              acquisition_per_unitvalue: proc {
                acquisition_entry&.acquisition_per_unit_value
              },
              acquisition_value_currency: proc {
                acquisition_entry&.acquisition_value_currency
              },
              acquisition_date: proc {
                acquisition_entry&.acquisition_date
              },
              acquisition_method: proc {
                acquisition_entry&.acquisition_method
              },
              acquisition_quantity: proc {
                acquisition_entry&.acquisition_quantity
              },
              acquisition_quantity_unit: proc {
                acquisition_entry&.acquisition_quantity_unit
              },
            },
            entry_callbacks: {
              before_validation: nil,
              validate: proc { |entry|
                if entries.by_entry_scopes("acquisition").where.not(id: entry.id).exists?
                  entry.errors.add(:type, :invalid)
                end
              },
              after_validation: nil,
              before_save: nil,
              after_save: nil
            },
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
              acquisition_value: proc {
                data.try(:acquisition_value)
              },
              acquisition_value_currency: proc {
                data.try(:acquisition_value_currency)
              },
              acquisition_date: proc {
                data.try(:acquisition_date)
              },
              acquisition_method: proc {
                self.class.entry_name
              }
            },
          },
          proxy: {
            functions: {
              value: proc {
                record.acquisition_value
              },
              value_currency: proc {
                record.acquisition_value_currency
              },
              date: proc {
                record.acquisition_date
              },
              acquisition_method: proc {
                record.acquisition_method
              }
            }
          }
        }
      end

    end
  end
end
