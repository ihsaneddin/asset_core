class Asset < ApplicationRecord

  belongs_to :owner, polymorphic: true

end