class AddPriceCuttingJonIdToTradeServices < ActiveRecord::Migration[7.0]
  def change
    change_table :trade_services do |t|
      t.string :price_cutting_job_id
    end
  end
end
