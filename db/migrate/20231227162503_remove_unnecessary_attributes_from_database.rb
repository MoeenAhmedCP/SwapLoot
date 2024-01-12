class RemoveUnnecessaryAttributesFromDatabase < ActiveRecord::Migration[7.0]
  def change
    remove_column :sellable_inventories, :sold_at, :datetime
    remove_column :sellable_inventories, :tradable, :boolean
    remove_column :trade_services, :price_cutting_status, :boolean
  end
end
