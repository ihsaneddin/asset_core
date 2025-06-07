class CreateAssets < ActiveRecord::Migration[7.0]
  def change
    create_table :assets do |t|
      t.references :owner, polymorphic: true
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
