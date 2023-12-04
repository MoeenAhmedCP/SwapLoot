class CreateTradeServices < ActiveRecord::Migration[7.0]
  def change
    create_table :trade_services do |t|
      t.boolean :buying_status, default: false
      t.boolean :selling_status, default: false
      t.string :selling_job_id
      t.string :buying_job_id
      t.references :steam_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
