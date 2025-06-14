module AssetCore
  module AssetScopes
    module Located

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :location do
        attributes(
          [
            address: {
              type: :string,
              validates: {
                presence: true
              }
            },
            city: {
              type: :string
            },
            state: {
              type: :string
            },
            country: {
              type: :string
            },
            postal_code: {
              type: :string
            },
            full_address: {
              type: :string
            },
            latitude: {
              type: :decimal,
              precision: 10,
              scale: 6
            },
            longitude: {
              type: :decimal,
              precision: 10,
              scale: 6
            },
          ]
        )
        callbacks.setup(
          **{
            before_save: proc {
              self.full_address = [address, city, state, country].join(" ").strip
            }
          }
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :located do
        proxy "location"
        entry_scopes([:location])
        relationships.setup(
          **{
            location_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:location)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            location_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:location)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
          }
        )
        callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
        entry_callbacks.setup(
          **{
            before_validation: nil,
            validate: nil,
            after_validation: nil,
            before_save: nil,
            after_save: nil,
          }
        )
        functions.setup(
          **{
            location: proc {
              location_entry&.full_address
            },
            location_latitude: proc {
              location_entry&.latitude
            },
            location_longitude: proc {
              location_entry&.longitude
            }
          }
        )
      end

    end
  end
end