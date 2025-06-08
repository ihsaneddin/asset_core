Organization.connection.truncate("organizations")
Address.connection.truncate("addresses")
Asset.connection.truncate("assets")
Invoice.connection.truncate("invoices")
AssetCore::Record.connection.truncate("asset_core_records")
AssetCore::Entry.connection.truncate("asset_core_entries")
AssetCore::State.connection.truncate("asset_core_states")
AssetCore::Model.connection.truncate("asset_core_models")
AssetCore::EntryItem.connection.truncate("asset_core_entry_items")

Organization::Company.asset_owner do
  name :name
  address proc { address_name }
  contact_number :contact_number
end

vendor = Organization::Vendor.create(name: "Vendor #1")

company = Organization::Company.create(name: "Company #1")
company.create_address(name: "Bandung")

Asset.acts_as_an_asset do
  name do
    name
  end
  description :description
  owner do
    owner
  end
end

#create asset record
asset = Asset.create(owner: company, name: "Asset #1")
#asset.update(asset_record_attributes: {  })
asset.create_asset_record

#create asset purchase entry using invoice
Invoice.asset_entry_reference do
  number do
    "Invoice ##{number}"
  end
  description :description
  data do
    {
      date: created_at,
      price: amount,
      currency: "RM"
    }
  end
end

asset.asset_record.purchase_entries.create(
  reference: Invoice.create(
    vendor: vendor,
    customer: company,
    number: SecureRandom.hex(8),
    amount: 100,
    currency: "RM",
    description: "Purchase of a thing"
  )
)

debugger

company


