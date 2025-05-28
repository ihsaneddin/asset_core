module AssetCore
  class State < AssetCore.config.application_record_base_constant

    self.table_name = 'asset_core_states'

    class_attribute :state_name
    self.state_name = name.demodulize.underscore

    belongs_to :record, class_name: "AssetCore::Record", foreign_key: :record_id
    belongs_to :previous_state, class_name: "AssetCore::State", foreign_key: :previous_state_id, optional: true
    belongs_to :reference, polymorphic: true, optional: true
    belongs_to :action, polymorphic: true, optional: true

    scope :with_record, -> (record) {
      if record.is_a?(::AssetCore::Record)
        where(record: record)
      else
        where(record_id: record)
      end
    }

    scope :effective_before, -> (time) {
      where("effective_at <= ?", time)
    }

    validate do
      if reference
        errors.add(:reference, :invalid) unless reference.class.include?(::AssetCore.decorators.asset_state_reference_methods)
      end
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.state_name= subclass.name.demodulize.underscore
      AssetCore::Record.define_state_relation(subclass)
    end

    def self.asset_record_state_config
      ::Plugins::Models::Concerns::Config.new({ state_list: [] })
    end

    def self.find_by_state_name(name)
      sub = subclasses.select{|sub| sub.state_name.to_s == name.to_s}[0]
      raise ArgumentError, "State name '#{name}' not found" unless sub
      sub
    end

    def data_sync(ref)
      ref
    end

    include ::AASM

    aasm :state, timestamps: true do
      state :draft, initial: true
      state :approved
      state :rejected

      event :approve do
        before do |effective_time|
          if effective_time
            self.effective_at = effective_time
          else
            self.effective_at ||= DateTime.now
          end
        end
        transitions from: [:draft], to: :approved
      end

      event :reject do
        transitions from: [:draft], to: :rejected
      end

    end

    before_create do
      if self.class.with_record(record_id).exists?
        prev_state = self.class.with_record(record_id).approved.effective_before(DateTime.now).order(effective_at: :desc).first
        self.previous_state = prev_state
      else
        self.initial= true
        approve
      end
    end

    before_save do
      if previous_state_id.blank? && effective_at.present?
        prev_state = self.class.with_record(record_id).approved.effective_before(effective_at).order(effective_at: :desc).first
        self.previous_state = prev_state
      end
    end

  end
end