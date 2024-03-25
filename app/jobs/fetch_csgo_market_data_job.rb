# app/jobs/fetch_csgo_market_data_job.rb

class FetchCsgoMarketDataJob
	include Sidekiq::Job

  def perform
    response = HTTParty.get('https://market.csgo.com/api/v2/prices/class_instance/USD.json')

    if response.success?
      parse_and_save_data(response.parsed_response)
    else
      Rails.logger.error("Failed to fetch data from the API. Response code: #{response.code}, Body: #{response.body}")
    end
  end

  private

  def parse_and_save_data(data)
    data['items'].each do |key, item|
      class_id, instance_id = key.split('_')
      
      market_data = {
        class_id: class_id,
        instance_id: instance_id,
        price: item['price'].to_f,
        avg_price: item['avg_price'].to_f,
        market_hash_name: item['market_hash_name']
      }

      MarketCsgoItemsData.create(market_data)
    end
  end
end
