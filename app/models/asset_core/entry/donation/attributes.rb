module AssetCore
  class Entry::Donation::Attributes < AssetCore::Attributes

    attribute :date, :date
    attribute :donor_name, :string
    attribute :estimated_value, :decimal, default: 0.0
    attribute :currency, :string
    attribute :notes, :string

    validates :date, timeliness: { type: :date }, if: :date
    validates :donor_name, presence: true
    validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }

    before_validation do
      self.donor_name ||= "anonymous"
    end

  end
end