class AddColumnsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :discord_channel_id, :string
    add_column :users, :discord_bot_token, :string
    add_column :users, :discord_app_id, :string
  end
end
