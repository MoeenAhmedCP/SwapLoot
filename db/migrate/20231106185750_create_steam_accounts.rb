class CreateSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :steam_accounts do |t|
      t.string :unique_name , null: false
      t.string :steam_id , null: false
      t.string :steam_web_api_key , null: false
      t.string :waxpeer_api_key
      t.string :csgoempire_api_key
      t.string :market_csgo_api_key
      t.boolean :active , default: false
      t.timestamps
    end
  end
end
