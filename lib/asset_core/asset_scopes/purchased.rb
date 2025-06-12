module AssetCore
  module AssetScopes
    module Purchased

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :purchase do
        requires([:quantifiable, :valuable])
        attributes(
          [
            date: {
              type: :date,
              validates: {
                timeliness: {type: :date}
              }
            }
          ]
        )
      end

      extend AssetCore::AssetScopes::Record

      define_record_scope :purchased do
        proxy "purchase"
        entry_scopes([:purchase])
        relationships.setup(
          **{
            purchase_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            purchase_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_classes_with_scopes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
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
                  asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                  asset_state.save
                end
              end
            }
          }
        )
        functions.setup(
          **{
            purchase_date: proc {
              purchase_entry&.date
            },
            purchase_value: proc {
              purchase_entry&.value
            },
            purchase_total_value: proc {
              purchase_entry&.total_value
            },
            purchase_quantity: proc {
              purchase_entry&.quantity
            },
            purchase_quantity_unit: proc {
              purchase_entry&.quantity_unit
            },
            purchase_currency: proc {
              purchase_entry&.currency
            }
          }
        )
      end

      def self.scope_options
        {
          record: {
            relationships: {
              purchase_entry: [:has_one, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
              purchase_entries: [:has_many, -> { where.not(effective_at: nil).where(state: "approved", type: ::AssetCore::Entry.get_scoped_classes(:purchase)).where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: "AssetCore::Entry", foreign_key: :record_id],
            },
            callbacks: {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: nil,
            },
            functions: {
              purchase_date: proc {
                purchase_entry&.purchase_date
              },
              purchase_value: proc {
                purchase_entry&.purchase_price
              },
              purchase_value_per_unit: proc {
                purchase_entry&.purchase_value_per_unit
              },
              purchase_quantity: proc {
                purchase_entry&.purchase_quantity
              },
              purchase_quantity_unit: proc {
                purchase_entry&.purchase_quantity_unit
              },
              purchase_currency: proc {
                purchase_entry&.purchase_price_currency
              }
            },
            entry_callbacks: {
              before_validation: nil,
              validate: nil,
              after_validation: nil,
              before_save: nil,
              after_save: proc { |entry|
                if entry.state == "approved" && entry.saved_change_to_state?
                  if asset
                    asset_state = entry.asset_ownership_states.new( record: self , index_name: "owned", use_reference_data: true)
                    asset_state.save
                  end
                end
              },
            }
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
              purchase_date: proc {
                data.date
              },
              purchase_value: proc {
                data.price
              },
              purchase_value_per_unit: proc {
                data&.unit_price
              },
              purchase_quantity: proc {
                data&.quantity
              },
              purchase_quantity_unit: proc {
                data&.quantity_unit
              },
              purchase_currency: proc {
                data.currency
              }
            }
          },
          proxy: {
            functions: {
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
        }
      end

    end
  end
end