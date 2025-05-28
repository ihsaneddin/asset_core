require 'securerandom'

module AssetCore
  class Entry < AssetCore.config.application_record_base_constant

    include ::Plugins::Models::Concerns::CustomAttributes

    custom_attributes_definition :data, ::AssetCore::Attributes

    self.table_name = 'asset_core_entries'

    class_attribute :entry_name
    self.entry_name = name.demodulize.underscore

    belongs_to :record, class_name: "AssetCore::Record", foreign_key: :record_id, optional: true
    belongs_to :previous_entry, class_name: "AssetCore::Entry", foreign_key: :previous_entry_id, optional: true
    belongs_to :reference, polymorphic: true, optional: true
    belongs_to :action, polymorphic: true, optional: true

    accepts_nested_attributes_for :data

    validates :data, store_model: true

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

    before_validation on: :create do
      self.number ||= generate_number
    end

    validate do
      if reference
        errors.add(:reference, :invalid) unless reference.class.include?(::AssetCore.decorators.asset_entry_reference_methods)
      end
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.entry_name= subclass.name.demodulize.underscore
      AssetCore::Record.define_entry_relation(subclass)
    end

    def self.asset_record_entry_config
      ::Plugins::Models::Concerns::Config.new({})
    end

    def self.find_by_entry_name(name)
      sub = subclasses.select{|sub| sub.entry_name.to_s == name.to_s}[0]
      raise ArgumentError, "Entry name '#{name}' not found" unless sub
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
        transitions from: [:draft], to: :approved
      end

    end

    before_create do
      if self.class.with_record(record_id).exists?
        prev_entry = self.class.with_record(record_id).approved.effective_before(DateTime.now).order(effective_at: :desc).first
        self.previous_entry = prev_entry
      else
        self.initial= true
        approve
      end
    end

    before_save do
      if previous_entry_id.blank? && effective_at.present?
        prev_entry = self.class.with_record(record_id).approved.effective_before(effective_at).order(effective_at: :desc).first
        self.previous_entry = prev_entry
      end
    end

    def generate_number
      SecureRandom.hex(8)
    end

  end
end