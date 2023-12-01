class CreatePriceEmpires < ActiveRecord::Migration[7.0]
  def change
    create_table :price_empires do |t|
      t.string :item_name
      t.float :liquidity
      t.json :buff
      t.json :waxpeer
      t.timestamps
    end
  end
end
