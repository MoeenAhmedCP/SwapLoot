class AddSoldAtToInventories < ActiveRecord::Migration[7.0]
  def change
    add_column :inventories, :sold_at, :datetime, default: nil
  end
end
