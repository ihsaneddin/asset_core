module AssetCore
  module AssetScopes
    module Valueable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :valuable do
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

          attribute :value, :decimal, default: 0
          attribute :currency, :string, default: "RM"
          attribute :total_value, :decimal, default: 0

          validates :value, numericality: { greater_than_or_equal_to: 0 }
          validates :currency, presence: true

        end

      end

    end
  end
end