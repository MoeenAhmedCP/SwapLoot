class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :item_id
      t.string :item_name
      t.date :date
      t.decimal :bought_price
      t.decimal :sold_price

      t.timestamps
    end
  end
end
