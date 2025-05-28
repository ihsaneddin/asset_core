module AssetCore
  class Entry::Purchase::Attributes < AssetCore::Attributes
    attribute :date, :date
    attribute :price, :decimal, default: 0.0
    attribute :currency, :string
    attribute :invoice_number, :string
    attribute :supplier_name, :string

    validates :date, timeliness: { type: :date, allow_blank: true }
    validates :price, numericality: { greater_than: 0 }, allow_blank: true
    validates :supplier_name, inclusion: { in: available_supplier_names }, if: :available_supplier_names

    def available_supplier_names
      if parent
        parent.default_data[:supplier_names]
      end
    end

  end
end