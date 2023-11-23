class CreateSellingFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :selling_filters do |t|
      t.integer :min_profit_percentage, default: 2
      t.integer :undercutting_price_percentage, default: 10
      t.integer :undercutting_interval, default: 12
      t.references :steam_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
