module AssetCore
  class State::Ownership::Attributes < AssetCore::Attributes

    self.protected_attributes = [:owned]

    attribute :owned, :boolean
    attribute :custodian_name
    attribute :custodian_address
    attribute :start_date, :date
    attribute :end_date, :date

    validates :start_date, timeliness: { type: :date }, allow_blank: true
    validates :end_date, timeliness: { type: :date }, allow_blank: true

  end
end