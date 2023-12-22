class RemoveColumnsFromInventories < ActiveRecord::Migration[7.0]
  def change
    remove_column :inventories, :sold_at, :datetime
    remove_column :inventories, :tradable, :boolean
  end
end
