require 'securerandom'
require 'hashdiff'

module AssetCore
  class Entry < AssetCore.config.application_record_base_constant

    include ::Plugins::Models::Concerns::PolymorphicAlternative
    include ::Plugins::Models::Concerns::CustomAttributes
    include ::AssetCore.decorators.asset_entry_scopes

    custom_attributes_definition :data, ::AssetCore::Attributes, accessor: true

    self.table_name = 'asset_core_entries'

    class_attribute :entry_name
    # self.entry_name = name.demodulize.underscore

    belongs_to :record, class_name: "AssetCore::Record", foreign_key: :record_id, optional: true
    belongs_to :previous_entry, class_name: "AssetCore::Entry", foreign_key: :previous_entry_id, optional: true
    belongs_to :reference, polymorphic: true, optional: true
    belongs_to :action, polymorphic: true, optional: true

    accepts_nested_attributes_for :data

    validates :data, store_model: { merge_errors: true }

    scope :with_record, -> (record) {
      if record.is_a?(::AssetCore::Record)
        where(record: record)
      else
        where(record_id: record)
      end
    }

    scope :by_entry_scopes, -> (*scopes) {
      types = ::AssetCore::Entry.descendants.select{|sub| sub.included_in_scopes?(*scopes) }.map(&:name)
      where(type: types)
    }

    scope :effective_before, -> (time) {
      where("effective_at <= ?", time)
    }

    before_validation :set_attributes_before_validation_on_create, on: :create
    with_options if: :reference do
      validate do
        errors.add(:reference, :invalid) unless valid_reference?
      end
    end

    def valid_reference?
      reference && reference.class.include?(::AssetCore.decorators.asset_entry_reference_methods)
    end

    def generate_number
      SecureRandom.hex(8)
    end

    def set_attributes_before_validation_on_create
      self.use_reference_data ||= record_asset_config_options[:use_reference_data]
      if use_reference_data
        attributes_use_asset_entry_reference
      else
        attributes_use_default_record_asset_config
      end
      self.number ||= generate_number
    end

    def attributes_use_asset_entry_reference()
      _data = reference_config_options()
      self.number = _data[:number]
      self.description = _data[:description]
      self.data.class.assignable_attributes.each do |att|
        self.send("#{att}=", _data[att.to_sym]) #if self.data.send(att).nil?
      end
    end

    def attributes_use_asset_entry_reference!()
      attributes_use_asset_entry_reference()
      save
    end

    def attributes_use_default_record_asset_config
      _data = record_asset_config_options
      self.number ||= _data[:number]
      self.description ||= _data[:description]
      self.data.class.assignable_attributes.each do |att|
        self.send("#{att}=", _data[att.to_sym]) if self.send(att).nil?
      end
    end

    def record_asset_config_options
      return @record_asset_config_options if @record_asset_config_options
      if record
        hash = {}
        hash[:use_reference_data] = record.asset.asset_config_defaults.entry_use_reference_data
        hash[:currency] = record.asset.asset_config_defaults.currency
        entry_name = self.class.entry_name
        if record.asset.asset_config.entries.send(entry_name).is_a?(self.class.plugins_config)
          hash[:number] = record.asset.asset_config.entries.send(entry_name).number
          hash[:description] = record.asset.asset_config.entries.send(entry_name).description
          unless record.asset.asset_config.entries.send(entry_name).use_reference_data.nil?
            hash[:use_reference_data] = record.asset.asset_config.entries.send(entry_name).use_reference_data
          end
          data_class = self.class.attribute_types['data'].model_klass
          data_class.assignable_attributes.each do |att|
            hash[att.to_sym] = record.asset.asset_config.entries.send(entry_name).send(att)
            if att.to_sym == :currency
              hash[att.to_sym] ||= hash[:currency]
            end
          end
        end
        @record_asset_config_options = hash
      end
      @record_asset_config_options || {}
    end

    def reference_config_options
      return @reference_config_options if @reference_config_options
      if reference && valid_reference?
        hash = {}
        ref_data = reference.asset_entry_reference_config_data(self) || {}
        data_class = self.class.attribute_types['data'].model_klass
        hash[:number] = ref_data[:index]
        hash[:description] = ref_data[:remark]
        data_class.assignable_attributes.each do |att|
          hash[att.to_sym] = ref_data[att.to_sym]
          if att.to_sym == :currency
            hash[att.to_sym] ||= record.asset.asset_config_defaults.currency
          end
        end
        @reference_config_options = hash
      end
      @reference_config_options || {}
    end

    def self.set_entry_name(_name = nil)
      self.entry_name = _name || self.name.demodulize.underscore
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.set_entry_name
      @entry_names ||= Set.new
      if @entry_names.include?(subclass.entry_name)
        raise ArgumentError, "Duplicate entry_name '#{name}' detected for #{subclass}"
      end
      AssetCore::Record.define_entry_relation(subclass)
      ::AssetCore::Models::Decorators::AssetEntryReference.reference_classes.each do |ref_class|
        ref_class.define_entry_subclass_relation(subclass)
      end
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
      }
      opts.merge!(data_opts)
      plugins_config.build(**opts)
    end

    def self.find_by_entry_name(name)
      sub = subclasses.select{|sub| sub.entry_name.to_s == name.to_s}[0]
      raise ArgumentError, "Entry name '#{name}' not found" unless sub
      sub
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
      # if ::AssetCore::Entry.with_entry_scopes(*self.class.asset_entry_scopes).with_record(record_id).exists?
      #   prev_entry = ::AssetCore::Entry.with_entry_scopes(*self.class.asset_entry_scopes).with_record(record_id).approved.effective_before(DateTime.now).order(effective_at: :desc).first
      #   self.previous_entry = prev_entry
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
        #prev_entry = ::AssetCore::Entry.with_entry_scopes(*self.class.asset_entry_scopes).with_record(record_id).approved.effective_before(DateTime.now).order(effective_at: :desc).first
        prev_entry = self.class.with_record(record_id).approved.effective_before(effective_at).order(effective_at: :desc).first
        self.previous_entry = prev_entry
      end
    end

  end
end