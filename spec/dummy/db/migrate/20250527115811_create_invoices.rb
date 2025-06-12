class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.references :customer, polymorphic: true, index: true
      t.references :vendor, polymorphic: true, index: true
      t.string :number
      t.date :date
      t.decimal :amount, precision: 10, scale: 6
      t.integer :quantity, default: 1
      t.decimal :total_amount, precision: 10, scale: 6
      t.string :currency, default: "RM"
      t.text :description
      t.timestamps
    end
  end
end
