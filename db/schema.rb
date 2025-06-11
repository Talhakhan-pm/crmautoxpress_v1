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

ActiveRecord::Schema[7.1].define(version: 2025_06_11_003204) do
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
    t.index ["trackable_type", "trackable_id", "created_at"], name: "index_activities_on_trackable_and_created_at"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
    t.index ["user_id", "created_at"], name: "index_activities_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "agent_callbacks", force: :cascade do |t|
    t.string "customer_name"
    t.string "phone_number"
    t.string "car_make_model"
    t.integer "year"
    t.text "product"
    t.string "zip_code"
    t.integer "status", default: 0
    t.date "follow_up_date"
    t.string "agent"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "communications_count", default: 0
    t.bigint "payment_link_id"
    t.integer "payment_amount_cents"
    t.index ["car_make_model"], name: "index_agent_callbacks_on_car_make_model"
    t.index ["communications_count"], name: "index_agent_callbacks_on_communications_count"
    t.index ["created_at", "status"], name: "index_agent_callbacks_on_created_at_and_status"
    t.index ["payment_link_id"], name: "index_agent_callbacks_on_payment_link_id"
    t.index ["status", "follow_up_date"], name: "index_agent_callbacks_on_status_and_follow_up_date"
    t.index ["user_id", "created_at"], name: "index_agent_callbacks_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_agent_callbacks_on_user_id"
  end

  create_table "communications", force: :cascade do |t|
    t.integer "agent_callback_id"
    t.integer "user_id"
    t.text "content"
    t.string "message_type", default: "note"
    t.boolean "is_urgent", default: false
    t.text "mentions"
    t.integer "parent_communication_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_callback_id", "created_at"], name: "index_communications_on_agent_callback_id_and_created_at"
    t.index ["agent_callback_id"], name: "index_communications_on_agent_callback_id"
    t.index ["created_at"], name: "index_communications_on_created_at"
    t.index ["message_type"], name: "index_communications_on_message_type"
    t.index ["parent_communication_id"], name: "index_communications_on_parent_communication_id"
    t.index ["user_id", "created_at"], name: "index_communications_on_user_and_created_at"
    t.index ["user_id"], name: "index_communications_on_user_id"
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
    t.index ["name"], name: "index_customers_on_name"
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
    t.index ["created_at", "dispatch_status"], name: "index_dispatches_on_created_at_and_status"
    t.index ["dispatch_status"], name: "index_dispatches_on_dispatch_status"
    t.index ["order_id"], name: "index_dispatches_on_order_id", unique: true
    t.index ["order_number"], name: "index_dispatches_on_order_number"
    t.index ["payment_status"], name: "index_dispatches_on_payment_status"
    t.index ["processing_agent_id"], name: "index_dispatches_on_processing_agent_id"
    t.index ["shipment_status"], name: "index_dispatches_on_shipment_status"
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "agent_callback_id"
    t.string "paypal_invoice_id"
    t.string "paypal_invoice_url"
    t.string "invoice_number"
    t.string "status", default: "draft"
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency", default: "USD"
    t.text "description"
    t.text "memo"
    t.string "business_name", default: "AutoXpress"
    t.string "business_email"
    t.string "customer_name"
    t.string "customer_email"
    t.string "customer_phone"
    t.string "billing_address_line1"
    t.string "billing_address_line2"
    t.string "billing_city"
    t.string "billing_state"
    t.string "billing_postal_code"
    t.string "billing_country", default: "US"
    t.string "shipping_address_line1"
    t.string "shipping_address_line2"
    t.string "shipping_city"
    t.string "shipping_state"
    t.string "shipping_postal_code"
    t.string "shipping_country", default: "US"
    t.datetime "due_date"
    t.datetime "paid_date"
    t.string "payment_method"
    t.text "paypal_response_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type"
    t.integer "source_id"
    t.index ["agent_callback_id"], name: "index_invoices_on_agent_callback_id"
    t.index ["customer_email"], name: "index_invoices_on_customer_email"
    t.index ["paypal_invoice_id"], name: "index_invoices_on_paypal_invoice_id"
    t.index ["source_type", "source_id"], name: "index_invoices_on_source"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.integer "communication_id"
    t.integer "agent_callback_id"
    t.string "notification_type", default: "new_communication"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_callback_id"], name: "index_notifications_on_agent_callback_id"
    t.index ["communication_id"], name: "index_notifications_on_communication_id"
    t.index ["notification_type", "created_at"], name: "index_notifications_on_type_and_created_at"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "notification_type", "read_at"], name: "index_notifications_on_user_type_read"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
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
    t.integer "supplier_id"
    t.string "supplier_order_number"
    t.decimal "supplier_cost", precision: 10, scale: 2
    t.string "supplier_shipment_proof"
    t.date "estimated_delivery_date"
    t.date "actual_delivery_date"
    t.integer "quality_rating"
    t.string "part_link"
    t.decimal "part_price", precision: 10, scale: 2
    t.decimal "supplier_shipping_cost", precision: 8, scale: 2
    t.decimal "supplier_tax", precision: 8, scale: 2
    t.integer "original_order_id"
    t.integer "replacement_order_id"
    t.string "replacement_reason"
    t.bigint "payment_link_id"
    t.index ["agent_callback_id"], name: "index_orders_on_agent_callback_id"
    t.index ["agent_id", "created_at"], name: "index_orders_on_agent_id_and_created_at"
    t.index ["agent_id"], name: "index_orders_on_agent_id"
    t.index ["created_at", "order_status"], name: "index_orders_on_created_at_and_status"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["customer_name"], name: "index_orders_on_customer_name"
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["order_status"], name: "index_orders_on_order_status"
    t.index ["original_order_id"], name: "index_orders_on_original_order_id"
    t.index ["payment_link_id"], name: "index_orders_on_payment_link_id"
    t.index ["priority"], name: "index_orders_on_priority"
    t.index ["processing_agent_id", "created_at"], name: "index_orders_on_processing_agent_and_created_at"
    t.index ["product_id"], name: "index_orders_on_product_id"
    t.index ["replacement_order_id"], name: "index_orders_on_replacement_order_id"
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
  end

  create_table "payment_links", force: :cascade do |t|
    t.integer "agent_callback_id"
    t.integer "user_id"
    t.decimal "amount", precision: 10, scale: 2
    t.string "product_description"
    t.string "customer_email"
    t.integer "status", default: 0
    t.string "stripe_payment_intent_id"
    t.string "stripe_checkout_session_id"
    t.string "payment_link_url"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "paid_at"
    t.datetime "expires_at"
    t.text "notes"
    t.text "customer_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_payment_link_id"
    t.string "stripe_price_id"
    t.string "provider", default: "paypal"
    t.string "paypal_invoice_id"
    t.string "paypal_payment_url"
    t.index ["agent_callback_id", "status"], name: "index_payment_links_on_agent_callback_id_and_status"
    t.index ["agent_callback_id"], name: "index_payment_links_on_agent_callback_id"
    t.index ["paypal_invoice_id"], name: "index_payment_links_on_paypal_invoice_id"
    t.index ["provider"], name: "index_payment_links_on_provider"
    t.index ["status", "created_at"], name: "index_payment_links_on_status_and_created_at"
    t.index ["stripe_payment_intent_id"], name: "index_payment_links_on_stripe_payment_intent_id"
    t.index ["user_id"], name: "index_payment_links_on_user_id"
  end

  create_table "paypal_invoices", force: :cascade do |t|
    t.integer "agent_callback_id"
    t.integer "order_id"
    t.integer "user_id"
    t.string "paypal_invoice_id"
    t.string "invoice_number"
    t.string "status", default: "DRAFT"
    t.decimal "amount", precision: 10, scale: 2
    t.string "currency_code", default: "USD"
    t.text "customer_details"
    t.text "line_items"
    t.string "paypal_invoice_url"
    t.text "invoice_note"
    t.datetime "sent_at"
    t.datetime "viewed_at"
    t.datetime "paid_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_callback_id", "status"], name: "index_paypal_invoices_on_agent_callback_id_and_status"
    t.index ["agent_callback_id"], name: "index_paypal_invoices_on_agent_callback_id"
    t.index ["invoice_number"], name: "index_paypal_invoices_on_invoice_number"
    t.index ["order_id"], name: "index_paypal_invoices_on_order_id"
    t.index ["paid_at"], name: "index_paypal_invoices_on_paid_at"
    t.index ["paypal_invoice_id"], name: "index_paypal_invoices_on_paypal_invoice_id"
    t.index ["sent_at"], name: "index_paypal_invoices_on_sent_at"
    t.index ["status", "created_at"], name: "index_paypal_invoices_on_status_and_created_at"
    t.index ["user_id"], name: "index_paypal_invoices_on_user_id"
  end

  create_table "paypal_webhooks", force: :cascade do |t|
    t.string "event_type"
    t.string "paypal_event_id"
    t.integer "paypal_invoice_id"
    t.text "raw_payload"
    t.boolean "processed", default: false
    t.text "processing_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type", "processed"], name: "index_paypal_webhooks_on_event_type_and_processed"
    t.index ["paypal_event_id"], name: "index_paypal_webhooks_on_paypal_event_id"
    t.index ["paypal_invoice_id"], name: "index_paypal_webhooks_on_paypal_invoice_id"
    t.index ["processed", "created_at"], name: "index_paypal_webhooks_on_processed_and_created_at"
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
    t.index ["name"], name: "index_products_on_name"
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
    t.integer "resolution_stage"
    t.text "agent_notes"
    t.text "dispatcher_notes"
    t.text "customer_response"
    t.text "corrected_customer_details"
    t.text "part_research_notes"
    t.decimal "price_difference"
    t.string "alternative_part_name"
    t.decimal "alternative_part_price"
    t.string "dispatcher_decision"
    t.integer "delay_duration"
    t.decimal "additional_cost"
    t.text "agent_instructions"
    t.integer "return_status", default: 0
    t.string "return_carrier"
    t.text "return_label_url"
    t.text "return_notes"
    t.datetime "return_authorized_at"
    t.datetime "return_shipped_at"
    t.datetime "return_received_at"
    t.index ["created_at", "refund_stage"], name: "index_refunds_on_created_at_and_stage"
    t.index ["order_id"], name: "index_refunds_on_order_id"
    t.index ["refund_date"], name: "index_refunds_on_refund_date"
    t.index ["refund_number"], name: "index_refunds_on_refund_number"
    t.index ["refund_stage"], name: "index_refunds_on_refund_stage"
    t.index ["return_status"], name: "index_refunds_on_return_status"
  end

  create_table "supplier_products", force: :cascade do |t|
    t.integer "supplier_id", null: false
    t.integer "product_id", null: false
    t.decimal "supplier_cost", precision: 10, scale: 2
    t.string "supplier_part_number"
    t.integer "lead_time_days"
    t.boolean "preferred_supplier", default: false
    t.date "last_quoted_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_supplier_products_on_product_id"
    t.index ["supplier_id", "product_id"], name: "index_supplier_products_on_supplier_id_and_product_id", unique: true
    t.index ["supplier_id"], name: "index_supplier_products_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.text "supplier_notes"
    t.integer "total_orders"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dialpad_user_id"
    t.integer "call_status", default: 0
    t.string "current_call_id"
    t.datetime "call_started_at"
    t.string "current_target_type"
    t.integer "current_target_id"
    t.index ["call_status"], name: "index_users_on_call_status"
    t.index ["current_call_id"], name: "index_users_on_current_call_id"
    t.index ["current_target_id"], name: "index_users_on_current_target_id"
    t.index ["current_target_type", "current_target_id", "call_status"], name: "index_users_on_target_and_call_status"
    t.index ["current_target_type", "current_target_id"], name: "index_users_on_current_target"
    t.index ["current_target_type"], name: "index_users_on_current_target_type"
    t.index ["dialpad_user_id"], name: "index_users_on_dialpad_user_id", unique: true, where: "dialpad_user_id IS NOT NULL"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activities", "users"
  add_foreign_key "agent_callbacks", "payment_links"
  add_foreign_key "agent_callbacks", "users"
  add_foreign_key "communications", "agent_callbacks"
  add_foreign_key "communications", "communications", column: "parent_communication_id"
  add_foreign_key "communications", "users"
  add_foreign_key "invoices", "agent_callbacks"
  add_foreign_key "notifications", "agent_callbacks"
  add_foreign_key "notifications", "communications"
  add_foreign_key "notifications", "users"
  add_foreign_key "orders", "payment_links"
  add_foreign_key "orders", "suppliers"
  add_foreign_key "payment_links", "agent_callbacks"
  add_foreign_key "payment_links", "users"
  add_foreign_key "paypal_invoices", "agent_callbacks"
  add_foreign_key "paypal_invoices", "orders"
  add_foreign_key "paypal_invoices", "users"
  add_foreign_key "paypal_webhooks", "paypal_invoices"
  add_foreign_key "refunds", "orders"
  add_foreign_key "refunds", "users", column: "processing_agent_id"
  add_foreign_key "supplier_products", "products"
  add_foreign_key "supplier_products", "suppliers"
end
