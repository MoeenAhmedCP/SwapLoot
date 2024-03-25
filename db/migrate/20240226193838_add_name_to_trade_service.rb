class AddNameToTradeService < ActiveRecord::Migration[7.0]
  def change
    add_column :trade_services, :market_type, :integer
  end
end
