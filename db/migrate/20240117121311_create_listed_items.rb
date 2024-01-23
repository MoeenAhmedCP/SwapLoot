class CreateListedItems < ActiveRecord::Migration[7.0]
  def change
    create_table :listed_items do |t|
      t.string :item_id
      t.string :item_name
      t.string :price
      t.string :site
      t.references :steam_account, foreign_key: true

      t.timestamps
    end
  end
end
