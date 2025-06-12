module AssetCore
  module AssetScopes
    module Valueable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :valuable do
        attributes(
          [
            value: {
              type: :decimal,
              default: 0,
              validates: {
                numericality: { greater_than_or_equal_to: 0 }
              }
            },
            currency: {
              type: :string,
              default: "RM"
            },
            total_value: {
              type: :decimal,
              default: 0,
              validates: {
                numericality: { greater_than: 0 }
              }
            },
          ]
        )
      end

    end
  end
end