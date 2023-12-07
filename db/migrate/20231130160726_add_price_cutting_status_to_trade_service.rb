class AddPriceCuttingStatusToTradeService < ActiveRecord::Migration[7.0]
  def change
    add_column :trade_services, :price_cutting_status, :boolean, default: false
  end
end
