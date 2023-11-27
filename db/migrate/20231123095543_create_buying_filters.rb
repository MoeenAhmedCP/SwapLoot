class CreateBuyingFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :buying_filters do |t|
      t.references :steam_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
