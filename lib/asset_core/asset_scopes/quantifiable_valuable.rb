module AssetCore
  module AssetScopes
    module QuantifiableValueable

      extend AssetCore::AssetScopes::Entry

      define_entry_scope :quantifiable_valuable do
        requires([:quantifiable, :valuable])
        callbacks.setup(
          **{
            after_validation: proc {
              self.total_value = value.to_d * quantity.to_d
            }
          }
        )
      end

    end
  end
end
