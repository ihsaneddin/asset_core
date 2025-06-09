module AssetCore
  class State::Ownership < AssetCore::State

    class Attributes < ::AssetCore::Attributes
      self.protected_attributes = [:owned]

      attribute :owned, :boolean
      attribute :custodian_name
      attribute :custodian_address
      attribute :start_date, :date
      attribute :end_date, :date

      validates :start_date, timeliness: { type: :date }, allow_blank: true
      validates :end_date, timeliness: { type: :date }, allow_blank: true

    end

    custom_attributes_definition :data, ::AssetCore::State::Ownership::Attributes

    self.states_list = [
      { name: "owned",        label: "Owned",        owned: true, default: true  },
      { name: "leased_in",    label: "Leased In",    owned: false },
      { name: "leased_out",   label: "Leased Out",   owned: true  },
      { name: "rented_in",    label: "Rented In",    owned: false },
      { name: "rented_out",   label: "Rented Out",   owned: true  },
      { name: "loaned_in",    label: "Loaned In",    owned: false },
      { name: "loaned_out",   label: "Loaned Out",   owned: true  },
      { name: "mortgage_in",  label: "Mortgage In",  owned: true  },
      { name: "mortgage_out", label: "Mortgage Out", owned: false },
      { name: "released",     label: "Released",     owned: false }
    ]

    before_save do
      if state_value[:owned]
        self.data.owned = true
      end
    end

  end
end