module AssetCore
  class Record::Single < ::AssetCore::Record

    class Attributes < ::AssetCore::Record::Attributes

      attribute :information, :string

    end

    custom_attributes_definition :data, Attributes, accesor: true

    define_asset_type :single, scopes: [ :acquisited, :purchased, :donated, :depreciated, :released ]

  end
end
