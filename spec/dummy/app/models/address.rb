class Address < ApplicationRecord

  belongs_to :addressable, polymorphic: true

  validates :name, presence: true

end