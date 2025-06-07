module AssetCore
  class State < AssetCore.config.application_record_base_constant

    extend ::AssetCore::Configuration::ConfigBuilder
    include ::Plugins::Models::Concerns::PolymorphicAlternative
    include ::Plugins::Models::Concerns::CustomAttributes

    custom_attributes_definition :data, ::AssetCore::Attributes

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

    before_validation :set_attributes_before_validation_on_create, on: :create

    validates :index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    validate do
      if reference
        errors.add(:reference, :invalid) unless reference.class.include?(::AssetCore.decorators.asset_state_reference_methods)
      end
    end

    after_validation do
      self.label ||= self.name.to_s.humanize
    end

    def set_attributes_before_validation_on_create
      if index_name
        self.index ||= find_state_index_with_name(index_name)
      end
      self.index ||= default_attributes_values[:index]
      self.remark ||= default_attributes_values[:remark]
      self.use_reference_data ||= default_attributes_values[:use_reference_data]
      if use_reference_data
        data_use_reference_data
      else
        data_use_default_attributes_values_data
      end
    end

    def self.inherited(subclass)
      super(subclass)
      subclass.state_name= subclass.name.demodulize.underscore
      subclass.states_list = states_list.dup
      AssetCore::Record.define_state_relation(subclass)
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
        data: plugins_config.build(**data_opts)
      }
      plugins_config.build(**opts)
    end

    def self.find_by_state_name(name)
      sub = subclasses.select{|sub| sub.state_name.to_s == name.to_s}[0]
      raise ArgumentError, "State name '#{name}' not found" unless sub
      sub
    end

    def default_attributes_values
      return @default_attributes_values if @default_attributes_values
      hash = {}
      if record && record.asset
        hash[:use_reference_data] = record.asset.config_defaults.state_use_reference_data
        hash[:manufacture]= record.asset.config_defaults.manufacture
        hash[:owner] = record.asset.config_defaults.owner
        hash[:data] = {}
        unless self.class.superclass == AssetCore.config.application_record_base_constant
          state_name = self.class.state_name
          hash[:index] = record.asset.asset_config.states.send(state_name).index
          hash[:remark] = record.asset.asset_config.states.send(state_name).remark
          hash[:states_list] = record.asset.asset_config.states.send(state_name).states_list
          unless record.asset.asset_config.states.send(entry_name).use_reference_data.nil?
            hash[:use_reference_data] = record.asset.asset_config.states.send(entry_name).use_reference_data
          end
          data_class =  AssetCore::Entry.attribute_types['data'].model_klass
          data_class.assignable_attributes.each do |att|
            hash[:data][att.to_sym] = record.asset.asset_config.states.send(state_name).data.send(att)
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

    def data_use_reference_data(ref=nil)
      ref ||= reference
      if ref.class.include?(::AssetCore.decorators.asset_state_reference_methods)
        ref_data = ref.asset_state_reference_config.data
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
      atts = data.attributes.symbolize_keys
      ref_data = ref.asset_state_reference_config.data.symbolize_keys.slice(*atts.keys)
      unless Hashdiff.diff(atts, ref_data).should == []
        data_use_reference_data!(ref)
      end
    end

    def states_list
      default_attributes_values[:states_list] || []
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