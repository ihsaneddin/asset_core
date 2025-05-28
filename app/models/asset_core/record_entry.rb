module AssetCore
  class RecordEntry #< AssetCore.config.application_record_base_constant

    # self.table_name = 'asset_core_record_entries'

    # belongs_to :record, class_name: "AssetCore::Record", foreign_key: :record_id
    # belongs_to :entry, class_name: "AssetCore::Entry", foreign_key: :entry_id

    # accepts_nested_attributes_for :entry
    # accepts_nested_attributes_for :purchase

    # def self.define_entry_relation(entry_class)
    #   return if entry_class.reflect_on_association(entry_class.entry_name.to_sym).present?
    #   belongs_to entry_class.entry_name.to_sym, class_name: entry_class.name, foreign_key: :entry_id, optional: true
    #   accepts_nested_attributes_for entry_class.entry_name.to_sym
    # end

  end
end