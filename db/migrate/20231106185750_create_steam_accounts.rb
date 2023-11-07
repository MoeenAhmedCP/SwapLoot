class CreateSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :steam_accounts do |t|
      t.string :steam_id
      t.string :steam_web_api_key
      t.string :waxpeer_api_key
      t.string :csgoempire_api_key
      t.string :market_csgo_api_key

      t.timestamps
    end
  end
end
