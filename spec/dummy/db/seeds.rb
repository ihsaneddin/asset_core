Organization.connection.truncate("organizations")
Address.connection.truncate("addresses")
Asset.connection.truncate("assets")
Invoice.connection.truncate("invoices")
AssetCore::Record.connection.truncate("asset_core_records")
AssetCore::Entry.connection.truncate("asset_core_entries")
AssetCore::State.connection.truncate("asset_core_states")
AssetCore::Model.connection.truncate("asset_core_models")
AssetCore::EntryItem.connection.truncate("asset_core_entry_items")

Organization.asset_owner do
  name :name
  address proc { address_name }
  contact_number :contact_number
end

company = Organization::Company.create(name: "Company #1")
company.create_address(name: "Bandung")

Asset.acts_as_an_asset do
  name :name
  description :description
end

asset = Asset.create(owner: company, name: "Asset #1")
asset.asset

debugger

company


