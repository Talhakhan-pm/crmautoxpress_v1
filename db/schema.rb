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

ActiveRecord::Schema[7.1].define(version: 2025_05_25_021917) do
  create_table "activities", force: :cascade do |t|
    t.string "trackable_type", null: false
    t.integer "trackable_id", null: false
    t.integer "user_id", null: false
    t.string "action"
    t.string "field_changed"
    t.text "old_value"
    t.text "new_value"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "agent_callbacks", force: :cascade do |t|
    t.string "customer_name"
    t.string "phone_number"
    t.string "car_make_model"
    t.integer "year"
    t.text "product"
    t.string "zip_code"
    t.integer "status"
    t.date "follow_up_date"
    t.string "agent"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_agent_callbacks_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone_number"
    t.string "email"
    t.text "full_address"
    t.string "source_campaign"
    t.string "gclid"
    t.string "utm_source"
    t.string "utm_campaign"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gclid"], name: "index_customers_on_gclid"
    t.index ["phone_number"], name: "index_customers_on_phone_number"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "part_number"
    t.string "oem_part_number"
    t.text "description"
    t.string "category"
    t.string "vendor_name"
    t.decimal "vendor_cost", precision: 10, scale: 2
    t.decimal "selling_price", precision: 10, scale: 2
    t.integer "lead_time_days"
    t.text "vehicle_compatibility"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["part_number"], name: "index_products_on_part_number"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activities", "users"
  add_foreign_key "agent_callbacks", "users"
end
