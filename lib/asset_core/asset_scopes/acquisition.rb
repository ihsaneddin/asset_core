module AssetCore
  module AssetScopes
    module Acquisition

      def self.scope_options
        {
          record_relationships: {
            has_one: [
              :acquisition_entry,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::AssetScopes.get_scoped_classes(:acquisition)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
          },
          entry_callbacks: {
            before_validation: nil,
            validate: proc {
              if record.entries.by_entry_scopes("acquisition").where.not(id: id).exists?
                errors.add(:type, :invalid)
              end
            },
            after_validation: nil,
            before_save: nil,
            after_save: nil,
          },
          entry_methods: {
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
          proxy_methods: {
            value: proc {
              record.acquisition_entry&.acquisition_value
            },
            value_currency: proc {
              record.acquisition_entry&.acquisition_value_currency
            },
            date: proc {
              record.acquisition_entry&.acquisition_date
            },
            acquisition_method: proc {
              record.acquisition_entry&.acquisition_method
            }
          }
        }
      end

      extend ::AssetCore::AssetScopes::Core

    end
  end
end