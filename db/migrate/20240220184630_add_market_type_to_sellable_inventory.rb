class AddMarketTypeToSellableInventory < ActiveRecord::Migration[7.0]
  def change
    add_column :sellable_inventories, :market_type, :integer
  end
end
