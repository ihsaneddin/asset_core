module AssetCore
  class Entry::Release::Attributes < AssetCore::Attributes

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
end