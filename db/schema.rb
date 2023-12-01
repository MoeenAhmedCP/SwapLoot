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

ActiveRecord::Schema[7.0].define(version: 2023_11_30_160726) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "buying_filters", force: :cascade do |t|
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_percentage", default: 20
    t.integer "max_price", default: 100
    t.integer "min_price", default: 50
    t.index ["steam_account_id"], name: "index_buying_filters_on_steam_account_id"
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
  end

  create_table "price_empires", force: :cascade do |t|
    t.string "item_name"
    t.float "liquidity"
    t.json "buff"
    t.json "waxpeer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "selling_filters", force: :cascade do |t|
    t.integer "min_profit_percentage", default: 2
    t.integer "undercutting_price_percentage", default: 10
    t.integer "undercutting_interval", default: 12
    t.bigint "steam_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["steam_account_id"], name: "index_selling_filters_on_steam_account_id"
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
    t.string "price_empire_api_key"
    t.index ["user_id"], name: "index_steam_accounts_on_user_id"
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
    t.boolean "price_cutting_status", default: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "buying_filters", "steam_accounts"
  add_foreign_key "selling_filters", "steam_accounts"
  add_foreign_key "steam_accounts", "users"
  add_foreign_key "trade_services", "steam_accounts"
end
