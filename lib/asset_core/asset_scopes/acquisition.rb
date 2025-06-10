module AssetCore
  module AssetScopes
    module Acquisition

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
              acquisition_value_currency: proc {
                acquisition_entry&.acquisition_value_currency
              },
              acquisition_date: proc {
                acquisition_entry&.acquisition_date
              },
              acquisition_method: proc {
                acquisition_entry&.acquisition_method
              }
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

      extend ::AssetCore::AssetScopes::Core

    end
  end
end
