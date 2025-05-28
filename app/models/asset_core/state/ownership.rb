module AssetCore
  class State::Ownership < AssetCore::Entry

    custom_attributes_definition :data, Attributes

    STATES = {
      "owned"       => true,
      "leased_in"   => false,
      "leased_out"  => true,
      "rented_in"   => false,
      "rented_out"  => true,
      "loaned_in"   => false,
      "loaned_out"  => true,
      "mortgage_in" => true,
      "mortgage_out"=> false
    }

    def self.asset_record_state_config
      opts = {
        state_list: STATES,
        default_state: "owned"
      }
      ::Plugins::Models::Concerns::Config.new(opts)
    end

    validates :state, presence: true, inclusion: { in: states_list }
    validate do
      if reference
        errors.add(:state, :invalid) unless record.class.include?(::AssetCore.decorators.asset_state_reference)
      end
    end

    def states_list
      if record
        record.asset.asset_config.states.ownerships.states_list || STATES
      end
    end

  end
end