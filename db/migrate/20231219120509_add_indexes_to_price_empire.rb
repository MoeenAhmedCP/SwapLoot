class AddIndexesToPriceEmpire < ActiveRecord::Migration[7.0]
  def change
    add_index :price_empires, :liquidity
  end
end
