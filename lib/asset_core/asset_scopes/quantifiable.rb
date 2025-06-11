module AssetCore
  module AssetScopes
    module Quantifiable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :quantifiable do
        functions.setup(
          **{
            quantity: proc {
              data.&(:quantity)
            },
            quantity_unit: proc {
              data.&(:quantity_unit)
            },
            quantity_unit_group: proc {
              if record
                record.asset.asset_config.quantity_unit_group
              end
            }
          }
        )
      end

      module Attributes
        include ActiveSupport::Concern

        included do
          attribute :quantity, :decimal, default: 1
          attribute :quantity_unit, :string

          validates :quantity, numericality: { greater_than: 0 }
          validates :quantity_unit, inclusion: { in: :available_quantity_units }

          validate do
            errors.add(:quantity_unit_group, :invalid) unless quantity_unit_group
          end

          after_validation :convert_to_base_unit
        end

        def quantity_unit_group
          parent.try(:quantity_unit_group)
        end

        def available_quantity_units
          (quantity_unit_group.try(:units) || []).map{|g| g[:name] }
        end

        def convert_to_base_unit
          self.quantity = quantity_unit_group.try(:conversion, quantity_unit, quantity_unit_group.base_unit)
          self.quantity_unit = quantity_unit_group.try(:base_unit)
        end
      end

    end
  end
end