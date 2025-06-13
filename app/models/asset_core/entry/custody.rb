module AssetCore
  class Entry::Custody < AssetCore::Entry

    self.abstract_class = true

    def self.set_entry_name
      if self == ::AssetCore::Entry::Custody
        self.entry_name = self.name.demodulize.underscore
      else
        self.entry_name = "#{::AssetCore::Entry::Custody.entry_name}_#{self.name.demodulize.underscore}"
      end
    end

    class Attributes < AssetCore::Attributes

      attribute :start_date, :date
      attribute :end_date, :date
      attribute :notes, :string

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :custodianship

  end
end