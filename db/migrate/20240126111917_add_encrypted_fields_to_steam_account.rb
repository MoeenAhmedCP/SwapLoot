class AddEncryptedFieldsToSteamAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :steam_accounts, :steam_account_name, :string
    add_column :steam_accounts, :steam_password, :string
    add_column :steam_accounts, :steam_identity_secret, :string
    add_column :steam_accounts, :steam_shared_secret, :string
  end
end
