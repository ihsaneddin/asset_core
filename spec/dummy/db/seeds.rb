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
asset.asset.states.ownership.current
asset.create_asset_record

#create asset purchase entry using invoice
Invoice.asset_entry_reference do
  data do
    {
      number: "Invoice ##{number}",
      description: description,
      date: date,
      value: amount,
      quantity: quantity,
      quantity_unit: "unit",
      currency: "RM"
    }
  end
  sync_data "sync"
end

#should create purchase entry for asset
purchase = asset.asset_record.purchase_entries.create(
  use_reference_data: true,
  reference: Invoice.create(
    date: Date.today,
    vendor: vendor,
    customer: company,
    number: SecureRandom.hex(8),
    amount: 100,
    currency: "RM",
    quantity: 1,
    description: "Purchase of a thing"
  )
)

unless purchase.persisted?
  raise "Test failed"
end

unless asset.asset.states.ownership.current&.state_name != "owned"
  raise "Test failed"
end

inv = Invoice.first
inv.update(amount:200)

purchase.reload

unless purchase.total_value == 200.to_d
  raise "Test failed"
end

#should fail purchase entry for asset
donation = asset.asset_record.purchase_entries.create(
  use_reference_data: true,
  date: Date.today,
  value: 100,
  currency: "RM",
  quantity: 1
)

if donation.persisted?
  raise "Test failed"
end

depreciation = asset.asset_record.depreciation_entries.create(
  expected_lifespan: 5,
  expected_lifespan_unit: "year",
  depreciation_method: "sum_of_years_digit",
  residual_value: 5,
  rate: 0.2
)
unless depreciation.persisted?
  raise "Test failed"
end

asset.asset_record.net_book_value( Date.today + 1.year).to_s
asset.asset.net_book_value(Date.today + 1.year)

release = asset.asset_record.release_entries.create(
  release_method: "sale",
  reason: nil,
)

unless release .persisted?
  raise "Test failed"
end

unless asset.asset.states.ownership.current&.state_name != "released"
  raise "Test failed"
end

new_asset = Asset.create(owner: company, name: "Asset #2")
new_asset.create_asset_record

custody_in = new_asset.asset_record.custody_in_entries.create(
  owner_name: "Any",
  owner_address: "Bandung",
  owner_contact: "2312313"
)

custody_transfer = new_asset.asset_record.custody_transfer_entries.create(
  custodian_name: "Any",
  custodian_address: "Bandung",
)

debugger
custody_in