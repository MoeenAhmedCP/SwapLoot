class AddColumnsToBuyingFilter < ActiveRecord::Migration[7.0]
  def change
    add_column :buying_filters, :min_percentage, :integer, default: 20
    add_column :buying_filters, :max_price, :integer, default: 100
    add_column :buying_filters, :min_price, :integer, default: 50
  end
end
