class Organization < ApplicationRecord

  belongs_to :parent, class_name: "Organization", foreign_key: "parent_id", optional: true
  has_one :address, as: :addressable, class_name: "Address"
  has_many :assets, as: :owner, class_name: "Asset"
  has_many :children, class_name: "Organization", foreign_key: "parent_id"

  delegate :name, :to => :address, prefix: true

end