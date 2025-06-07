class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices do |t|
      t.string :number
      t.decimal :amount, precision: 10, scale: 6
      t.timestamps
    end
  end
end
