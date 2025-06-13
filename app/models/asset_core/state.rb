module AssetCore
  class State < AssetCore.config.application_record_base_constant

    extend ::AssetCore::Configuration::ConfigBuilder
    include ::Plugins::Models::Concerns::PolymorphicAlternative
    include ::Plugins::Models::Concerns::CustomAttributes

    custom_attributes_definition :data, ::AssetCore::Attributes, accessor: true

    self.table_name = 'asset_core_states'

    class_attribute :state_name
    self.state_name = name.demodulize.underscore
    class_attribute :states_list
    self.states_list = [
      { name: "state", label: "State", default: true }
    ]

    attr_accessor :index_name

    belongs_to :record, class_name: "AssetCore::Record", foreign_key: :record_id
    belongs_to :previous_state, class_name: "AssetCore::State", foreign_key: :previous_state_id, optional: true
    belongs_to :reference, polymorphic: true, optional: true
    belongs_to :action, polymorphic: true, optional: true

    accepts_nested_attributes_for :data

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

    before_validation do
      if self.index_name
        self.index = self.find_state_index_with_name(self.index_name)
      end
    end
    before_validation :set_attributes_before_validation_on_create, on: :create
    with_options if: :reference do
      validate do
        errors.add(:reference, :invalid) unless valid_reference?
      end
    end

    validates :index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_create do
      if self.class.with_record(record_id).exists?
        prev_state = self.class.with_record(record_id).approved.effective_before(DateTime.now).order(effective_at: :desc).first
        self.previous_state = prev_state
      else
        self.initial= true
        approve if may_approve?
      end
    end

    before_save do
      if previous_state_id.blank? && effective_at.present?
        prev_state = self.class.with_record(record_id).approved.effective_before(effective_at).order(effective_at: :desc).first
        self.previous_state = prev_state
      end
    end

    def valid_reference?
      reference && reference.class.include?(::AssetCore.decorators.asset_state_reference_methods)
    end

    def set_attributes_before_validation_on_create
      self.use_reference_data ||= record_asset_config_options[:use_reference_data]
      if use_reference_data
        attributes_use_asset_state_reference
      else
        attributes_use_default_record_asset_config
      end
    end

    def attributes_use_asset_state_reference()
      _data = reference_config_options()
      self.index = _data[:index]
      self.remark = _data[:remark]
      self.data.class.assignable_attributes.each do |att|
        self.send("#{att}=", data[att.to_sym]) #if self.data.send(att).nil?
      end
    end

    def attributes_use_asset_state_reference!
      attributes_use_asset_state_reference
      save
    end

    def attributes_use_default_record_asset_config
      _data = record_asset_config_options
      self.index ||= _data[:index]
      self.remark ||= _data[:remark]
      self.data.class.assignable_attributes.each do |att|
        self.send("#{att}=", data[att.to_sym]) if self.send(att).nil?
      end
    end

    def record_asset_config_options
      return @record_asset_config_options if @record_asset_config_options
      if record
        hash = {}
        hash[:use_reference_data] = record.asset.asset_config_defaults.entry_use_reference_data
        hash[:currency] = record.asset.asset_config_defaults.currency
        state_name = self.class.state_name
        if record.asset.asset_config.states.send(state_name).is_a?(self.class.plugins_config)
          hash[:index] = record.asset.asset_config.states.send(state_name).index
          hash[:remark] = record.asset.asset_config.states.send(state_name).remark
          unless record.asset.asset_config.states.send(state_name).use_reference_data.nil?
            hash[:use_reference_data] = record.asset.asset_config.states.send(state_name).use_reference_data
          end
          data_class = self.class.attribute_types['data'].model_klass
          data_class.assignable_attributes.each do |att|
            hash[att.to_sym] = record.asset.asset_config.states.send(state_name).send(att)
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
        ref_data = reference.asset_state_reference_config.data || {}
        hash[:index] = ref_data[:index]
        hash[:remark] = ref_data[:remark]
        data_class = self.class.attribute_types['data'].model_klass
        data_class.assignable_attributes.each do |att|
          hash[att.to_sym] = ref_data[att.to_sym]
        end
        @reference_config_options = hash
      end
      @reference_config_options || {}
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.state_name= subclass.name.demodulize.underscore
      @state_names ||= Set.new
      if @state_names.include?(subclass.state_name)
        raise ArgumentError, "Duplicate state_name '#{name}' detected for #{subclass}"
      end
      subclass.states_list = states_list.dup
      AssetCore::Record.define_state_relation(subclass)
      ::AssetCore::Models::Decorators::AssetStateReference.reference_classes.each do |ref_class|
        ref_class.define_state_subclass_relation(subclass)
      end
    end

    def self.asset_record_state_config
      data_opts = attribute_types["data"].model_klass.assignable_attributes.inject({}) do |hash, att|
        hash[att.to_sym] = nil
        hash
      end
      opts = {
        index: nil,
        remark: nil,
        use_reference_data: nil,
        states_list: states_list,
      }
      plugins_config.build(**opts.merge(data_opts))
    end

    def self.find_by_state_name(name)
      sub = subclasses.select{|sub| sub.state_name.to_s == name.to_s}[0]
      raise ArgumentError, "State name '#{name}' not found" unless sub
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
        transitions from: [:draft], to: :rejected
      end

    end

    def states_list
      self.class.states_list || []
    end

    def state_name
      (states_list[index] || {}).dig(:name)
    end

    def state_label
      (states_list[index] || {}).dig(:label)
    end

    def default_state_index
      states_list.find_index{|s| ( s || {}).dig(:default) }
    end

    def state_value
      states_list[index] || {}
    end

    def find_state_index_with_name _name
      states_list.find_index{|s| ( s || {}).dig(:name) == _name }
    end

  end
end