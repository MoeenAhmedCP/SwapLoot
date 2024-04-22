class CreateMarketCsgoActiveOffers < ActiveRecord::Migration[7.0]
  def change
    create_table :market_csgo_active_offers do |t|
      t.string :trade_url
      t.string :asset_id

      t.timestamps
    end
  end
end
