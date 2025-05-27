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

ActiveRecord::Schema[7.1].define(version: 2025_05_27_105130) do
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
    t.text "details"
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

  create_table "dispatches", force: :cascade do |t|
    t.integer "order_id"
    t.string "order_number"
    t.string "customer_name"
    t.text "customer_address"
    t.string "product_name"
    t.string "car_details"
    t.string "condition", default: "new"
    t.string "payment_processor"
    t.integer "payment_status", default: 0
    t.integer "processing_agent_id"
    t.string "supplier_name"
    t.string "supplier_order_number"
    t.decimal "supplier_cost", precision: 10, scale: 2
    t.string "supplier_shipment_proof"
    t.decimal "product_cost", precision: 10, scale: 2
    t.decimal "tax_amount", precision: 8, scale: 2
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.decimal "total_cost", precision: 10, scale: 2
    t.string "tracking_number"
    t.string "tracking_link"
    t.integer "shipment_status", default: 0
    t.integer "dispatch_status", default: 0
    t.text "comments"
    t.text "internal_notes"
    t.string "last_modified_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispatch_status"], name: "index_dispatches_on_dispatch_status"
    t.index ["order_id"], name: "index_dispatches_on_order_id", unique: true
    t.index ["order_number"], name: "index_dispatches_on_order_number"
    t.index ["payment_status"], name: "index_dispatches_on_payment_status"
    t.index ["processing_agent_id"], name: "index_dispatches_on_processing_agent_id"
    t.index ["shipment_status"], name: "index_dispatches_on_shipment_status"
    t.index ["supplier_name"], name: "index_dispatches_on_supplier_name"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number"
    t.datetime "order_date"
    t.string "customer_name"
    t.text "customer_address"
    t.string "customer_phone"
    t.string "customer_email"
    t.string "product_name"
    t.integer "car_year"
    t.string "car_make_model"
    t.integer "order_status"
    t.decimal "product_price", precision: 10, scale: 2
    t.decimal "tax_amount", precision: 8, scale: 2
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "tracking_number"
    t.string "product_link"
    t.date "estimated_delivery"
    t.text "comments"
    t.text "internal_notes"
    t.string "last_modified_by"
    t.integer "agent_callback_id"
    t.integer "customer_id"
    t.integer "product_id"
    t.integer "agent_id"
    t.integer "processing_agent_id"
    t.integer "priority", default: 1
    t.string "source_channel"
    t.integer "warranty_period_days", default: 30
    t.text "warranty_terms"
    t.integer "return_window_days", default: 14
    t.decimal "commission_amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_callback_id"], name: "index_orders_on_agent_callback_id"
    t.index ["agent_id"], name: "index_orders_on_agent_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["order_status"], name: "index_orders_on_order_status"
    t.index ["priority"], name: "index_orders_on_priority"
    t.index ["product_id"], name: "index_orders_on_product_id"
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
    t.string "source", default: "callback"
    t.index ["category"], name: "index_products_on_category"
    t.index ["part_number"], name: "index_products_on_part_number"
    t.index ["source"], name: "index_products_on_source"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "refunds", force: :cascade do |t|
    t.integer "order_id"
    t.integer "processing_agent_id"
    t.string "refund_number"
    t.datetime "refund_date"
    t.string "customer_name"
    t.string "customer_email"
    t.decimal "original_charge_amount", precision: 10, scale: 2
    t.decimal "refund_amount", precision: 10, scale: 2
    t.integer "refund_stage", default: 0
    t.integer "refund_reason"
    t.string "order_status"
    t.string "agent_name"
    t.text "notes"
    t.text "internal_notes"
    t.string "payment_processor"
    t.string "transaction_id"
    t.string "refund_method"
    t.text "bank_details"
    t.integer "estimated_processing_days", default: 7
    t.datetime "completed_at"
    t.string "last_modified_by"
    t.integer "priority", default: 1
    t.string "replacement_order_number"
    t.string "return_tracking_number"
    t.datetime "return_deadline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_refunds_on_order_id"
    t.index ["refund_date"], name: "index_refunds_on_refund_date"
    t.index ["refund_number"], name: "index_refunds_on_refund_number"
    t.index ["refund_stage"], name: "index_refunds_on_refund_stage"
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
  add_foreign_key "refunds", "orders"
  add_foreign_key "refunds", "users", column: "processing_agent_id"
end
