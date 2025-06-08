class Invoice < ApplicationRecord

  belongs_to :customer, polymorphic: true, optional: true
  belongs_to :vendor, polymorphic: true

end