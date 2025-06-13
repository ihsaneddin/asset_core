module AssetCore
  module AssetScopes
    module Quantifiable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :quantifiable do
        attributes(
          [
            quantity_unit: {
              type: :string,
              validates: {
                inclusion: {
                  in: proc{ |entry| entry.quantity_unit_group&.units&.map{|u| u[:name]} || [] }
                }
              }
            },
            quantity: {
              type: :decimal,
              default: 1,
              validates: {
                numericality: { greater_than: 0 }
              }
            },
          ]
        )
        callbacks.setup(
          **{
            validate: proc {
              errors.add(:quantity_unit_group, :invalid) unless quantity_unit_group
            },
            after_validation: proc{
              self.quantity= quantity_unit_group.conversion(quantity, quantity_unit, quantity_unit_group.base_unit)
              self.quantity_unit= quantity_unit_group.base_unit
            }
          }
        )
        functions.setup(
          **{
            quantity_unit_group: proc {
              if record
                record.asset.asset_config.quantity_unit_group
              end
            },
          }
        )
      end

    end
  end
end