class RemovePriceCuttingFromTradeServices < ActiveRecord::Migration[7.0]
  def change
    remove_column :trade_services, :price_cutting_status, :boolean
  end
end
