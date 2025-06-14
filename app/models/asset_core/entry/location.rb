module AssetCore
  class Entry::Location < AssetCore::Entry

    class Attributes < AssetCore::Attributes

      attribute :address, :string
      attribute :city, :string
      attribute :state, :string
      attribute :country, :string
      attribute :full_address, :string
      attribute :postal_code, :string
      attribute :latitude, :decimal, precision: 10, scale: 6
      attribute :longitude, :decimal, precision: 10, scale: 6

    end

    custom_attributes_definition :data, Attributes, accessor: true

    define_asset_entry_scopes :location

  end
end