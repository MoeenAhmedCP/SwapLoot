class CreateSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :steam_accounts do |t|
      t.string :unique_name , null: false
      t.string :steam_id , null: false, unique: true
      t.string :steam_web_api_key , null: false, unique: true
      t.string :waxpeer_api_key, unique: true
      t.string :csgoempire_api_key, unique: true
      t.string :market_csgo_api_key, unique: true
      t.boolean :active , default: false
      t.timestamps
    end
  end
end
