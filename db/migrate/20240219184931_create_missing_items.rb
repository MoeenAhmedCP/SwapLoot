class CreateMissingItems < ActiveRecord::Migration[7.0]
  def change
    create_table :missing_items do |t|
      t.string :item_id
      t.string :market_name
      t.string :market_value
      t.string :steam_account_id
      t.timestamps
    end
  end
end
