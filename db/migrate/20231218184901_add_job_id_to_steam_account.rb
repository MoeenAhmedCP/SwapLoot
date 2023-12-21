class AddJobIdToSteamAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :steam_accounts, :sold_item_job_id, :string
  end
end
