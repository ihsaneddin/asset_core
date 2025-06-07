class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.references :parent, index: true
      t.string :name
      t.string :contact_number
      t.string :type
      t.timestamps
    end
  end
end
