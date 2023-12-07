class ChangeInventoryPriceType < ActiveRecord::Migration[7.0]
  def change
    change_column :inventories, :market_price, :float
  end
end
