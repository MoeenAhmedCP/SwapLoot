class ChangeDefaultValuesOfSellingAndBuyingProfitPercentages < ActiveRecord::Migration[7.0]
  def change
    change_column_default :selling_filters, :min_profit_percentage, 15
    change_column_default :buying_filters, :min_percentage, 7
  end
end
