module AssetCore
  class Entry::Donation < AssetCore::Entry

    class DonationAttributes < AssetCore::EntryAttributes
      attribute :date, :date
      attribute :donor_name, :string
      attribute :estimated_value, :decimal, default: 0.0
      attribute :currency, :string
      attribute :notes, :string

      validates :date, timeliness: { type: :date }
      validates :donor_name, presence: true
      validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }

      before_validation do
        self.donor_name ||= "anonymous"
      end

    end

    custom_attribute_definitions :data, DonationAttributes.type

    def donation_date
      data.date
    end

    def donor_name
      data.donor_name
    end

    def estimated_value
      data.estimated_value
    end

    def currency
      data.currency
    end

    def notes
      data.notes
    end

    def purchase_price
      0.0
    end

    def acquisition_value
      estimated_value
    end

  end
end