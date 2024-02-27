class AddMarketTypeToSellingFilter < ActiveRecord::Migration[7.0]
  def change
    add_column :selling_filters, :market_type, :integer
    add_column :buying_filters, :market_type, :integer
  end
end
