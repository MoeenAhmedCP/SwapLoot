class CreateMarketCsgoItemsData < ActiveRecord::Migration[7.0]
  def change
    create_table :market_csgo_items_data do |t|
      t.string :class_id
      t.string :instance_id
      t.float :price
      t.float :avg_price
      t.string :market_hash_name

      t.timestamps
    end
  end
end
