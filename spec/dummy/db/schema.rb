# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_06_08_162746) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "addressable_type"
    t.bigint "addressable_id"
    t.string "name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "asset_core_entries", force: :cascade do |t|
    t.bigint "record_id"
    t.string "reference_type"
    t.bigint "reference_id"
    t.bigint "previous_entry_id"
    t.string "action_type"
    t.bigint "action_id"
    t.string "number"
    t.text "description"
    t.string "state"
    t.datetime "rejected_at"
    t.datetime "approved_at"
    t.datetime "effective_at"
    t.boolean "use_reference_data", default: false
    t.text "remark"
    t.boolean "initial", default: false
    t.boolean "batch", default: false
    t.jsonb "data", default: {}
    t.jsonb "metadata", default: {}
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type", "action_id"], name: "index_asset_core_entries_on_action"
    t.index ["previous_entry_id"], name: "index_asset_core_entries_on_previous_entry_id"
    t.index ["record_id"], name: "index_asset_core_entries_on_record_id"
    t.index ["reference_type", "reference_id"], name: "index_asset_core_entries_on_reference"
  end

  create_table "asset_core_entry_items", force: :cascade do |t|
    t.bigint "entry_id"
    t.string "reference_type"
    t.bigint "reference_id"
    t.string "number"
    t.text "description"
    t.jsonb "data"
    t.jsonb "metadata"
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_asset_core_entry_items_on_entry_id"
    t.index ["reference_type", "reference_id"], name: "index_asset_core_entry_items_on_reference"
  end

  create_table "asset_core_generics", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "asset_core_models", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "name"
    t.string "number"
    t.text "description"
    t.string "state"
    t.jsonb "data"
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_asset_core_models_on_owner"
  end

  create_table "asset_core_record_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
  end

  create_table "asset_core_records", force: :cascade do |t|
    t.string "asset_type"
    t.bigint "asset_id"
    t.bigint "model_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.bigint "parent_id"
    t.string "name"
    t.text "description"
    t.string "number"
    t.string "tag_number"
    t.string "state"
    t.datetime "registered_at"
    t.datetime "discharged_at"
    t.jsonb "data"
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type", "asset_id"], name: "index_asset_core_records_on_asset"
    t.index ["model_id"], name: "index_asset_core_records_on_model_id"
    t.index ["owner_type", "owner_id"], name: "index_asset_core_records_on_owner"
    t.index ["parent_id"], name: "index_asset_core_records_on_parent_id"
  end

  create_table "asset_core_states", force: :cascade do |t|
    t.bigint "record_id"
    t.bigint "previous_state_id"
    t.string "reference_type"
    t.bigint "reference_id"
    t.string "action_type"
    t.bigint "action_id"
    t.integer "index"
    t.string "state"
    t.datetime "rejected_at"
    t.datetime "approved_at"
    t.datetime "effective_at"
    t.boolean "use_reference_data", default: false
    t.text "remark"
    t.boolean "initial", default: false
    t.jsonb "data", default: {}
    t.jsonb "metadata", default: {}
    t.string "type"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type", "action_id"], name: "index_asset_core_states_on_action"
    t.index ["previous_state_id"], name: "index_asset_core_states_on_previous_state_id"
    t.index ["record_id"], name: "index_asset_core_states_on_record_id"
    t.index ["reference_type", "reference_id"], name: "index_asset_core_states_on_reference"
  end

  create_table "assets", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_assets_on_owner"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "customer_type"
    t.bigint "customer_id"
    t.string "vendor_type"
    t.bigint "vendor_id"
    t.string "number"
    t.date "date"
    t.decimal "amount", precision: 10, scale: 6
    t.string "currency", default: "RM"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_type", "customer_id"], name: "index_invoices_on_customer"
    t.index ["vendor_type", "vendor_id"], name: "index_invoices_on_vendor"
  end

  create_table "organizations", force: :cascade do |t|
    t.bigint "parent_id"
    t.string "name"
    t.string "contact_number"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_organizations_on_parent_id"
  end

end
