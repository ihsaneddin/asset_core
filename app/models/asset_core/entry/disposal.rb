module AssetCore
  class Entry::Disposal < AssetCore::Entry

    class DisposalAttributes < AssetCore::EntryAttributes
      attribute :date, :date
      attribute :disposal_method, :string
      attribute :proceeds_amount, :decimal, default: 0.0
      attribute :currency, :string
      attribute :reason, :string

      validates :disposal_date, timeliness: { type: :date }
      validates :disposal_method, presence: true, inclusion: { in: %w[sale donation scrap write_off] }
      validates :proceeds_amount, numericality: { greater_than_or_equal_to: 0 }
      validates :currency, presence: true
    end

    custom_attribute_definitions :data, DisposalAttributes.type

    def disposal_date
      data.date
    end

    def disposal_method
      data.disposal_method
    end

    def proceeds_amount
      data.proceeds_amount
    end

    def currency
      data.currency
    end

    def reason
      data.reason
    end

    #TODO
    def gain_or_loss(as_of: Date.today)
      return nil unless record.respond_to?(:accrued_depreciation) && record.respond_to?(:purchase_price)

      carrying_value = record.purchase_price - record.accrued_depreciation(as_of: as_of)
      proceeds_amount - carrying_value
    end

    def fully_depreciated?(as_of: Date.today)
      return false unless record.respond_to?(:net_book_value)

      record.net_book_value(as_of: as_of).zero?
    end
  end
end