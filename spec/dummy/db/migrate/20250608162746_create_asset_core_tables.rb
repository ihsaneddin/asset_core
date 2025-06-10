class CreateAssetCoreTables < ActiveRecord::Migration[7.0]
  def up

    create_table :asset_core_records, force: :cascade do |t|
      #relationships
      t.references :asset, polymorphic: true, index: true
      t.references :model, index: true
      t.references :owner, polymorphic: true, index: true
      t.references :parent, index: true

      #core fields
      t.string :name
      t.text :description
      t.string :number
      t.string :tag_number

      #functionality fields
      t.string :state
      t.datetime :registered_at
      t.datetime :discharged_at

      #helper fields
      t.jsonb :data, default: {}

      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :asset_core_models, force: :cascade do |t|
      #relationships
      t.references :owner, polymorphic: true, index: true

      #core fields
      t.string :name
      t.string :number
      t.text :description

      #functionality fields
      t.string :state

      #helper fields
      t.jsonb :data

      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :asset_core_record_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end

    create_table :asset_core_entries, force: :cascade do |t|
      t.references :record, index: true
      t.references :reference, polymorphic: true, index: true
      t.references :previous_entry, index: true
      t.references :action, polymorphic: true, index: true

      #core field
      t.string :number
      t.text :description
      t.string :state
      t.datetime :rejected_at
      t.datetime :approved_at
      t.datetime :effective_at
      t.boolean :use_reference_data, default: false

      t.text :remark
      t.boolean :initial, default: false
      t.boolean :batch, default: false

      t.jsonb :data, default: {}
      t.jsonb :metadata, default: {}
      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :asset_core_entry_items, force: :cascade do |t|
      t.references :entry, index: true
      t.references :reference, polymorphic: true, index: true
      t.string :number
      t.text :description
      t.jsonb :data
      t.jsonb :metadata
      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :asset_core_states, force: :cascade do |t|
      t.references :record, index: true
      t.references :previous_state, index: true
      t.references :reference, polymorphic: true, index: true
      t.references :action, polymorphic: true, index: true

      t.integer :index

      t.string :state
      t.datetime :rejected_at
      t.datetime :approved_at
      t.datetime :effective_at
      t.boolean :use_reference_data, default: false

      t.text :remark
      t.boolean :initial, default: false
      t.jsonb :data, default: {}
      t.jsonb :metadata, default: {}
      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :asset_core_generics, force: :cascade do |t|
      t.string :name
      t.text :description
      t.string :type
      t.datetime :deleted_at
      t.timestamps
    end

  end

  def down
    drop_table :asset_core_records
    drop_table :asset_core_models
    drop_table :asset_core_record_hierarchies
    drop_table :asset_core_entries
    drop_table :asset_core_entry_items
    drop_table :asset_core_states
    drop_table :asset_core_generics
  end
end