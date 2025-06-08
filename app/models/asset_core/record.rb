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

    with_options if: :asset do
      before_validation on: :create do
        if valid_asset?
          attributes_use_default_asset_config
        end
      end

      validate do
        errors.add(:asset, :invalid) unless valid_asset?
      end
    end

    with_options if: :owner do
      validate do
        errors.add(:owner, :invalid) unless valid_owner?
      end
    end

    def valid_asset?
      asset && asset.class.include?(::AssetCore.decorators.asset_methods)
    end

    def valid_owner?
      owner && owner.class.include?(::AssetCore.decorators.asset_owner_methods)
    end

    def self.inherited sub
      super(sub)
      sub.asset_type = sub.name.demodulize.underscore
    end

    def self.define_entry_relation(entry_class)
      return if reflect_on_association(entry_class.entry_name.pluralize.to_sym).present?
      has_many "#{entry_class.entry_name}_entries".to_sym, class_name: entry_class.name, foreign_key: :record_id
      has_one "current_#{entry_class.entry_name}_entry".to_sym, -> { where.not(effective_at: nil).where(state: "approved").where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: entry_class.name, foreign_key: :record_id
    end

    def self.define_state_relation(state_class)
      return if reflect_on_association(state_class.state_name.pluralize.to_sym).present?
      has_many "#{state_class.state_name}_states".to_sym, class_name: state_class.name, foreign_key: :record_id
      has_one "current_#{state_class.state_name}_state".to_sym, -> { where.not(effective_at: nil).where(state: "approved").where("effective_at <= ? ", DateTime.now).order(effective_at: :desc) }, class_name: state_class.name, foreign_key: :record_id
    end

    def self.find_by_asset_type(name)
      sub = subclasses.select{|sub| sub.asset_type == name.to_s}[0]
      raise ArgumentError, "Asset type '#{name}' not found" unless sub
      sub
    end

    def attributes_use_default_asset_config
      _data = asset_config_options
      self.name ||= _data[:name]
      self.description ||= _data[:description]
      self.owner ||= _data[:owner]
      self.number ||= _data[:number]
      self.tag_number ||=  _data[:tag_number]
    end

    def attributes_use_default_asset_config!
      attributes_use_default_asset_config
      save
    end

    def asset_config_options
      return @asset_config_options if @asset_config_options
      if asset && valid_asset?
        hash = {}
        hash[:name] = asset.asset_config_name
        hash[:description] = asset.asset_config_description
        hash[:owner] = asset.asset_config.owner
        hash[:number] = asset.asset_config_number_generator
        hash[:tag_number] = asset.asset_config_tag_number_generator
        @asset_config_options = hash
      end
      @asset_config_options || {}
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