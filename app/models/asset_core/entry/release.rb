module AssetCore
  class Entry::Release < AssetCore::Entry

    custom_attributes_definition :data, Attributes

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