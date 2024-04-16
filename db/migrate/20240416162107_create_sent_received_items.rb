class CreateSentReceivedItems < ActiveRecord::Migration[7.0]
  def change
    create_table :sent_received_items do |t|
      t.string :item_id, null: false
      t.string :trade_offer_id, null: false
      t.string :market_name, null: false
      t.integer :trade_type
      t.timestamps
    end
  end
end
