class AddIndexesToSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    add_index :steam_accounts, :steam_id
    add_index :steam_accounts, :waxpeer_api_key
    add_index :steam_accounts, :csgoempire_api_key
    add_index :steam_accounts, :market_csgo_api_key
  end
end
