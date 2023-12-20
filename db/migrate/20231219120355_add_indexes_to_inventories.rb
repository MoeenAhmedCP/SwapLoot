class AddIndexesToInventories < ActiveRecord::Migration[7.0]
  def change
    add_index :inventories, :item_id
    add_index :inventories, :market_price
    add_index :inventories, :market_name
  end
end
