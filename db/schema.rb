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

ActiveRecord::Schema[7.0].define(version: 2024_01_22_120653) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "bid_items", force: :cascade do |t|
    t.integer "deposit_id"
    t.string "item_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deposit_id"], name: "index_bid_items_on_deposit_id"
    t.index ["item_name"], name: "index_bid_items_on_item_name"
  end

  create_table "buying_filters", force: :cascade do |t|
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_percentage", default: 7
    t.integer "max_price", default: 100
    t.integer "min_price", default: 50
    t.index ["steam_account_id"], name: "index_buying_filters_on_steam_account_id"
  end

  create_table "errors", force: :cascade do |t|
    t.string "message", default: ""
    t.string "backtrace", default: [], array: true
    t.string "error_type", default: "StandardError"
    t.boolean "handled", default: false
    t.string "severity", default: "error"
    t.json "context", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_errors_on_user_id"
  end

  create_table "inventories", force: :cascade do |t|
    t.string "item_id"
    t.string "market_name"
    t.float "market_price"
    t.boolean "tradable"
    t.string "steam_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sold_at"
    t.index ["item_id"], name: "index_inventories_on_item_id", unique: true
    t.index ["market_name"], name: "index_inventories_on_market_name"
    t.index ["market_price"], name: "index_inventories_on_market_price"
  end

  create_table "listed_items", force: :cascade do |t|
    t.string "item_id"
    t.string "item_name"
    t.string "price"
    t.string "site"
    t.bigint "steam_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_account_id"], name: "index_listed_items_on_steam_account_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.string "notification_type"
    t.boolean "is_read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "price_empires", force: :cascade do |t|
    t.string "item_name"
    t.float "liquidity"
    t.json "buff"
    t.json "waxpeer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["liquidity"], name: "index_price_empires_on_liquidity"
  end

  create_table "proxies", force: :cascade do |t|
    t.string "ip"
    t.integer "port"
    t.string "username"
    t.string "password"
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_account_id"], name: "index_proxies_on_steam_account_id"
  end

  create_table "sellable_inventories", force: :cascade do |t|
    t.string "item_id"
    t.string "market_name"
    t.string "market_price"
    t.string "steam_id"
    t.boolean "listed_for_sale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "selling_filters", force: :cascade do |t|
    t.integer "min_profit_percentage", default: 15
    t.integer "undercutting_price_percentage", default: 10
    t.integer "undercutting_interval", default: 3
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_account_id"], name: "index_selling_filters_on_steam_account_id"
  end

  create_table "sold_item_histories", force: :cascade do |t|
    t.string "item_id"
    t.string "item_name"
    t.date "date"
    t.decimal "bought_price"
    t.decimal "sold_price"
    t.bigint "steam_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_account_id"], name: "index_sold_item_histories_on_steam_account_id"
  end

  create_table "sold_items", force: :cascade do |t|
    t.string "item_id"
    t.string "item_name"
    t.date "date"
    t.decimal "bought_price"
    t.decimal "sold_price"
    t.bigint "steam_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_sold_items_on_item_id"
    t.index ["item_name"], name: "index_sold_items_on_item_name"
    t.index ["steam_account_id"], name: "index_sold_items_on_steam_account_id"
  end

  create_table "steam_accounts", force: :cascade do |t|
    t.string "unique_name", null: false
    t.string "steam_id", null: false
    t.string "steam_web_api_key", null: false
    t.string "waxpeer_api_key"
    t.string "csgoempire_api_key"
    t.string "market_csgo_api_key"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "sold_item_job_id"
    t.index ["csgoempire_api_key"], name: "index_steam_accounts_on_csgoempire_api_key"
    t.index ["market_csgo_api_key"], name: "index_steam_accounts_on_market_csgo_api_key"
    t.index ["steam_id"], name: "index_steam_accounts_on_steam_id"
    t.index ["user_id"], name: "index_steam_accounts_on_user_id"
    t.index ["waxpeer_api_key"], name: "index_steam_accounts_on_waxpeer_api_key"
  end

  create_table "trade_services", force: :cascade do |t|
    t.boolean "buying_status", default: false
    t.boolean "selling_status", default: false
    t.string "selling_job_id"
    t.string "buying_job_id"
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "price_cutting_job_id"
    t.index ["steam_account_id"], name: "index_trade_services_on_steam_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.string "discord_channel_id"
    t.string "discord_bot_token"
    t.string "discord_app_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "buying_filters", "steam_accounts"
  add_foreign_key "errors", "users"
  add_foreign_key "listed_items", "steam_accounts"
  add_foreign_key "proxies", "steam_accounts"
  add_foreign_key "selling_filters", "steam_accounts"
  add_foreign_key "sold_item_histories", "steam_accounts"
  add_foreign_key "sold_items", "steam_accounts"
  add_foreign_key "steam_accounts", "users"
  add_foreign_key "trade_services", "steam_accounts"
end
