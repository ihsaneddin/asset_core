module AssetCore
  class Entry::Inventory < AssetCore::Entry

    class Attributes < ::AssetCore::Attributes
      attribute :quantity, :decimal, default: 0
      attribute :quantity_unit, :string
      attribute :notes, :string
      attribute :missing, :boolean, default: false

      validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    end

    custom_attributes_definition :data, Attributes

    def quantity
      data.quantity
    end

    def quantity_unit
      data.quantity_unit
    end

    def notes
      data.notes
    end

    def missing?
      missing
    end


  end
end