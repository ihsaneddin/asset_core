require 'securerandom'
require 'hashdiff'

module AssetCore
  class Entry < AssetCore.config.application_record_base_constant

    include ::Plugins::Models::Concerns::PolymorphicAlternative
    include ::Plugins::Models::Concerns::CustomAttributes
    include ::AssetCore.decorators.asset_scopes

    custom_attributes_definition :data, ::AssetCore::Attributes

    asset_state_reference do
      description :description
    end

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

    scope :by_entry_scopes, -> (*scopes) {
      types = ::AssetCore::Entry.descendants.select{|sub| sub.included_in_scopes(*scopes) }.map(&:name)
      where(type: types)
    }

    scope :effective_before, -> (time) {
      where("effective_at <= ?", time)
    }

    before_validation :set_attributes_before_validation_on_create, on: :create

    validate do
      if reference
        errors.add(:reference, :invalid) unless reference.class.include?(::AssetCore.decorators.asset_entry_reference_methods)
      end
    end

    def set_attributes_before_validation_on_create
      self.number ||= default_attributes_values[:number]
      self.number ||= generate_number
      self.description ||= default_attributes_values[:description]
      self.use_reference_data ||= default_attributes_values[:use_reference_data]
      if use_reference_data
        data_use_reference_data
      else
        data_use_default_attributes_values_data
      end
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.entry_name= subclass.name.demodulize.underscore
      AssetCore::Record.define_entry_relation(subclass)
    end

    def self.asset_record_entry_config
      data_opts = attribute_types["data"].model_klass.assignable_attributes.inject({}) do |hash, att|
        hash[att.to_sym] = nil
        hash
      end
      opts = {
        number: nil,
        description: nil,
        use_reference_data: nil,
        data: plugins_config.build(**data_opts)
      }
      plugins_config.build(**opts)
    end

    def self.find_by_entry_name(name)
      sub = subclasses.select{|sub| sub.entry_name.to_s == name.to_s}[0]
      raise ArgumentError, "Entry name '#{name}' not found" unless sub
      sub
    end

    def default_attributes_values
      return @default_attributes_values if @default_attributes_values
      hash = {}
      if record
        hash[:use_reference_data] = record.asset.config_defaults.entry_use_reference_data
        hash[:manufacture]= record.asset.config_defaults.manufacture
        hash[:owner] = record.asset.config_defaults.owner
        hash[:currency] = record.asset.config_defaults.currency
        hash[:data] = {}
        unless self.class.superclass == AssetCore.config.application_record_base_constant
          entry_name = self.class.entry_name
          hash[:number] = record.asset.asset_config.entries.send(entry_name).number
          hash[:description] = record.asset.asset_config.entries.send(entry_name).description
          unless record.asset.asset_config.entries.send(entry_name).use_reference_data.nil?
            hash[:use_reference_data] = record.asset.asset_config.entries.send(entry_name).use_reference_data
          end
          data_class =  AssetCore::Entry.attribute_types['data'].model_klass
          data_class.assignable_attributes.each do |att|
            hash[:data][att.to_sym] = record.asset.asset_config.entries.send(entry_name).data.send(att)
            if att.to_sym == :currency
              hash[:data][att.to_sym] ||= hash[:currency]
            end
          end
        end
      end
      @default_attributes_values = hash
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

    def data_use_reference_data(ref=nil)
      ref ||= reference
      if ref.class.include?(::AssetCore.decorators.asset_entry_reference_methods)
        ref_data = ref.asset_entry_reference_config.data
        self.data.class.assignable_attributes.each do |att|
          self.data.send("#{att}=", ref_data[att.to_sym])
        end
        self.data
      end
    end

    def data_use_reference_data!(ref=nil)
      save if data_use_reference_data
    end

    def data_use_default_attributes_values_data
      _data = default_attributes_values[:data]
      self.data.class.assignable_attributes.each do |att|
        self.data.send("#{att}=", _data[att.to_sym]) if self.data.send(att).nil?
      end
    end

    def data_sync(ref)
      atts = data.class.assignable_attributes.symbolize_keys
      ref_data = ref.asset_entry_reference_config.data.symbolize_keys.slice(*atts.keys)
      unless Hashdiff.diff(atts, ref_data).should == []
        data_use_reference_data!(ref)
      end
    end

  end
end