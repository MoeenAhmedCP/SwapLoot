class RemovePriceEmpireApiKeyFromSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    remove_column :steam_accounts, :price_empire_api_key, :string
  end
end
