module AssetCore
  module AssetScopes
    module QuantifiableValueable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :quantifiable_valuable do
        functions.setup(
          **{
            value: proc {
              data.&(:value)
            },
            total_value: proc {
              data.&(:total_value)
            },
            value_currency: proc {
              data.&(:total_value)
            }
          }
        )
      end

      module Attributes

        include ActiveSupport::Concern
        included do
          include AssetCore::AssetScopes::Quantifiable::Attributes
          include AssetCore::AssetScopes::Valuable::Attributes

          after_validation do
            self.total_value = value.to_d * quantity.to_d
          end

        end
      end

    end
  end
end
