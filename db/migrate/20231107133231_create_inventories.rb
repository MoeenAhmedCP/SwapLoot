class CreateInventories < ActiveRecord::Migration[7.0]
  def change
    create_table :inventories do |t|
      t.string :item_id
      t.string :market_name
      t.integer :market_price
      t.boolean :tradable
      t.string :steam_id
      t.timestamps
    end
  end
end
