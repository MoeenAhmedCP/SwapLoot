class AddValidAccountToSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :steam_accounts, :valid_account, :boolean, default: false
  end
end
