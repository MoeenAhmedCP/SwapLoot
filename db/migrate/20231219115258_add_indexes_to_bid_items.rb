class AddIndexesToBidItems < ActiveRecord::Migration[7.0]
  def change
    add_index :bid_items, :deposit_id
    add_index :bid_items, :item_name
  end
end
