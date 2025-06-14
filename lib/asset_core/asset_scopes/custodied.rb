module AssetCore
  module AssetScopes
    module Custodied

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :custodianship do
        requires([:quantifiable, :valuable])
        attributes(
          [
            start_date: {
              type: :date,
              validates: {
                timeliness: {type: :date}
              }
            },
            notes: {
              type: :string
            },
            end_date: {
              type: :date,
              validates: {
                timeliness: {type: :date},
                allow_blank: true
              }
            }
          ]
        )
        callbacks.setup(
          **{
            before_validation: proc {
              self.start_date ||= Date.today
            }
          }
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :custodied do
        proxy "custodianship"
        entry_scopes([:custodianship])
        relationships.setup(
          **{
            custodianship_entries: [
              :has_many,
              -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:custodianship)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
              class_name: "AssetCore::Entry",
              foreign_key: :record_id
            ],
          }
        )
      end

      module CustodyIn
        extend AssetCore::AssetScopes::Entry

        define_entry_scope :custody_in do
          requires([:custodianship])
          attributes(
            [
              owner_name: {
                type: :string
              },
              owner_address: {
                type: :string
              },
              owner_contact: {
                type: :string
              },
              custody_type: {
                type: :string
              },
              notes: {
                type: :string
              },
            ]
          )
        end

        extend AssetCore::AssetScopes::Record
        define_record_scope :custodied_in do
          proxy "custody_in"
          requires([:custodied])
          entry_scopes([:custody_in])
          relationships.setup(
            **{
              custody_in_entry: [
                :has_one,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:custody_in)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
              custody_in_entries: [
                :has_many,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:custody_in)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
            }
          )
          callbacks.setup(**{ before_validation: nil, validate: nil, after_validation: nil, before_save: nil, after_save: nil })
          functions.setup(
            **{
              custody_in_value: proc {
               custody_in_entry&.value
              },
              custody_in_total_value: proc {
               custody_in_entry&.total_value
              },
              custody_in_value_currency: proc {
               custody_in_entry&.currency
              },
              custody_in_method: proc {
               custody_in_entry&.custodied_in_method
              },
              custody_in_quantity: proc {
               custody_in_entry&.quantity
              },
              custody_in_quantity_unit: proc {
               custody_in_entry&.quantity_unit
              },
              custody_in_owner_name: proc {
               custody_in_entry&.owner_name
              },
              custody_in_owner_address: proc {
                custody_in_entry&.owner_address
              },
              custody_in_owner_contact: proc {
               custody_in_entry&.owner_contact
              },
              custody_in_start_date: proc {
               custody_in_entry&.start_date
              },
              custody_in_end_date: proc {
                custodyin_entry&.end_date
              },
              custody_in_notes: proc {
               custody_in_entry&.notes
              },
              custody_in_custody_type: proc {
               custody_in_entry&.custody_type
              },
            }
          )
          entry_callbacks.setup(
            **{
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: proc { |entry|
                if entry.state == "approved" && entry.saved_change_to_state?
                  if asset
                    asset_state = entry.asset_ownership_states.new( record: self , index_name: "custody_in", use_reference_data: true)
                    asset_state.save
                  end
                end
              }
            }
          )
        end


      end

      module CustodyTransfer
        extend AssetCore::AssetScopes::Entry

        define_entry_scope :custody_transfer do
          requires([:custodianship])
          attributes(
            [
              custodian_name: {
                type: :string,
                validates: {
                  presence: true
                }
              },
              custodian_address: {
                type: :string
              },
              custodian_contact: {
                type: :string
              },
              custodian_organization_name: {
                type: :string
              },
              notes: {
                type: :string
              },
            ]
          )
        end

        extend AssetCore::AssetScopes::Record
        define_record_scope :custody_transfer do
          proxy "custody_transfer"
          requires([:custodied])
          entry_scopes([:custody_transfer])
          relationships.setup(
            **{
              custody_transfer_entry: [
                :has_one,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:custody_transfer)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
              custody_transfer_entries: [
                :has_many,
                -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:custody_transfer)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) },
                class_name: "AssetCore::Entry",
                foreign_key: :record_id
              ],
            }
          )
          entry_callbacks.setup(
            **{
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: proc { |entry|
                if created_at == updated_at
                  location_entries.create(reference: entry, use_reference_data: true)
                end
              }
            }
          )
        end


      end

    end
  end
end
