class AddValidationToInventories < ActiveRecord::Migration[7.0]
  def change
    remove_index :inventories, :item_id
    add_index :inventories, :item_id, unique: true
  end
end
