class AddUserReferenceToSteamAccounts < ActiveRecord::Migration[7.0]
  def change
    add_reference :steam_accounts, :user, foreign_key: true
  end
end
