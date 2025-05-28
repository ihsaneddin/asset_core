module AssetCore
  class Entry::Purchase < AssetCore::Entry

    custom_attributes_definition :data, Attributes

    before_validation prepend: true, on: :create do
      self.number ||= default_data[:number]
      self.use_data_reference ||= default_data[:use_data_reference]
      self.data.date ||= default_data[:date]
      self.data.currency ||= default_data[:currency]
      self.data.supplier_name ||= default_data[:supplier_name]
      if use_data_reference && reference.class.include?(::AssetCore.decorators.asset_entry_reference_methods)
        self.description = reference.asset_entry_reference_config.description
        self.data.date = reference.asset_entry_reference_config.data[:date]
        self.data.currency = reference.asset_entry_reference_config.data[:currency]
        self.data.invoice_number = reference.asset_entry_reference_config.data[:invoice_number]
        self.data.price = reference.asset_entry_reference_config.data[:price]
        self.data.supplier_name = reference.asset_entry_reference_config.data[:supplier_name]
      end
    end

    def self.asset_record_entry_config
      opts = {
        number: nil,
        description: nil,
        currency: nil,
        date: nil,
        supplier_name: nil,
        supplier_names: nil,
        use_data_reference: false,
      }
      ::Plugins::Models::Concerns::Config.new(opts)
    end

    def default_data
      return @default_data if @default_data
      hash = super
      if record && record.asset
        if record.asset.asset_config.entries.purchase.currency
          hash[:currency] = record.asset.asset_config.entries.purchase.currency
        end
        unless record.asset.asset_config.entries.purchase.use_data_reference.nil?
          hash[:use_data_reference] = record.asset.asset_config.entries.purchase.use_data_reference
        end
        hash[:supplier_name] = record.asset.asset_config.entries.purchase.supplier_name
        hash[:supplier_names] = record.asset.asset_config.entries.purchase.supplier_names
        hash[:date] = record.asset.asset_config.entries.purchase.date
        hash[:number] = record.asset.asset_config.entries.purchase.number
        hash[:description] = record.asset.asset_config.entries.purchase.description
      end
      @default_data = hash
    end

    def data_sync(ref)

    end

  end
end