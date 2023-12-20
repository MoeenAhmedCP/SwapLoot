class AddIndexesToSoldItems < ActiveRecord::Migration[7.0]
  def change
    add_index :sold_items, :item_id
    add_index :sold_items, :item_name
  end
end
