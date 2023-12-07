class CreateBidItems < ActiveRecord::Migration[7.0]
  def change
    create_table :bid_items do |t|
      t.integer :deposit_id
      t.string :item_name

      t.timestamps
    end
  end
end
