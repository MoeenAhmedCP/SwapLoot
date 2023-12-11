class ChangeDefaultUndercuttingInterval < ActiveRecord::Migration[7.0]
  def change
    change_column_default :selling_filters, :undercutting_interval, 3
  end
end
