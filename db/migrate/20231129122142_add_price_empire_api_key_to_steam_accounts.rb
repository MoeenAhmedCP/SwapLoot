class AddPriceEmpireApiKeyToSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :steam_accounts, :price_empire_api_key, :string, default: nil
  end
end
