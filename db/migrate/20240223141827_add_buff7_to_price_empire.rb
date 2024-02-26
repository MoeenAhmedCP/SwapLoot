class AddBuff7ToPriceEmpire < ActiveRecord::Migration[7.0]
  def change
    add_column :price_empires, :buff_avg7, :json
  end
end
