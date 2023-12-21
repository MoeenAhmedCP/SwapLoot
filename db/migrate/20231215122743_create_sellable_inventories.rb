class CreateSellableInventories < ActiveRecord::Migration[7.0]
  def change
    create_table :sellable_inventories do |t|
      t.string :item_id
      t.string :market_name
      t.string :market_price
      t.string :steam_id
      t.boolean :listed_for_sale
      t.boolean :tradable
      t.datetime :sold_at

      t.timestamps
    end
  end
end
