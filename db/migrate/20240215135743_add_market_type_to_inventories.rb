class AddMarketTypeToInventories < ActiveRecord::Migration[7.0]
  def change
    add_column :inventories, :market_type, :integer
  end
end
