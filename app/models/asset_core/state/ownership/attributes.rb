module AssetCore
  class State::Ownership::Attributes < AssetCore::Attributes

    attribute :owned, :boolean
    attribute :custodian_name
    attribute :start_date, :date
    attribute :end_date, :date

    validates :start_date, timeliness: { type: date }, allow_blank: true
    validates :end_date, timeliness: { type: date }, allow_blank: true


  end
end