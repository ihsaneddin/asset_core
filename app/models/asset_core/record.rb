module AssetCore
  class Record < AssetCore.config.application_record_base_constant

    include ::Plugins::Models::Concerns::PolymorphicAlternative

    self.table_name = 'asset_core_records'

    class_attribute :asset_type
    self.asset_type = self.name.demodulize.underscore

    has_closure_tree hierarchy_table_name: 'asset_core_record_hierarchies', dependent: :destroy

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :asset, polymorphic: true
    belongs_to :model, class_name: "AssetCore::Model", optional: true
    has_many :entries, class_name: "AssetCore::Entry", foreign_key: :record_id, dependent: :destroy, inverse_of: :record
    has_many :states, class_name: "AssetCore::State", foreign_key: :record_id, dependent: :destroy, inverse_of: :record

    accepts_nested_attributes_for :entries, allow_destroy: true
    accepts_nested_attributes_for :states, allow_destroy: true

    before_validation on: :create do
      if asset.class.include?(::AssetCore.decorators.asset_methods)
        self.name ||= ref.asset_config_name
        self.description ||= ref.asset_config_description
        self.owner ||= asset.asset_config.defaults.owner
        self.number ||= asset.asset_config_number_generator
        self.tag_number ||=  asset.asset_config_tag_number_generator
        self.number = "#{asset.asset_config_number_prefix}#{self.number}#{asset.asset_config_number_suffix}"
        self.tag_number = "#{asset.asset_config_tag_number_prefix}#{self.tag_number}#{asset.asset_config_tag_number_suffix}"
      end
    end

    validate do
      if asset
        errors.add(:asset, :invalid) unless asset.class.include?(::AssetCore.decorators.asset_methods)
      end
    end

    validate do

    end

    def self.inherited sub
      super(sub)
      sub.asset_type = sub.name.demodulize.underscore
    end

    def self.define_entry_relation(entry_class)
      return if reflect_on_association(entry_class.entry_name.pluralize.to_sym).present?
      has_many "entry_#{entry_class.entry_name.pluralize}".to_sym, class_name: entry_class.name, foreign_key: :record_id
      has_one "current_entry_#{entry_class.entry_name}".to_sym, -> { where.not(effective_at: nil).where(state: "approved").where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: entry_class.name, foreign_key: :record_id
    end

    def self.define_state_relation(state_class)
      return if reflect_on_association(state_class.state_name.pluralize.to_sym).present?
      has_many "state_#{state_class.state_name.pluralize}".to_sym, class_name: state_class.name, foreign_key: :record_id
      has_one "current_state_#{state_class.state_name}".to_sym, -> { where.not(effective_at: nil).where(state: "approved").where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: state_class.name, foreign_key: :record_id
    end

    def self.find_by_asset_type(name)
      sub = subclasses.select{|sub| sub.asset_type == name.to_s}[0]
      raise ArgumentError, "Asset type '#{name}' not found" unless sub
      sub
    end

    def data_sync(ref)
      if ref.asset_config_name != name || ref.asset_config_description != description
        update name: ref.asset_config_name, description: ref.asset_config_description
      end
    end

    def asset_config
      return @_asset_config if @_asset_config
      if asset
        @_asset_config = asset.asset_config
      end
      @_asset_config
    end

  end
end