class PriceEmpireSuggestedPriceJob
	include Sidekiq::Job
    
    def perform
        p "<---------------- Price Empire Suggested price Job Started ---------->"
        ActiveRecord::Base.transaction do
            PriceEmpire.destroy_all
            begin
                # response = HTTParty.get("https://api.pricempire.com/v3/items/prices?api_key=012c1691-f511-4545-ab78-cf6b5b2b1b38&currency=USD&sources=buff&sources=waxpeer&sources=csgoempire")
                response = HTTParty.get("https://api.pricempire.com/v3/items/prices?api_key=#{ENV['PRICEEMPIRE_API_KEY']}&currency=USD&sources=buff&sources=waxpeer&sources=csgoempire")
                unless JSON.parse(response.body)["statusCode"] == 403
                    response.each do |item|
                        PriceEmpire.create!(item_name: item[0], liquidity: item[1]["liquidity"], buff: item[1]["buff"], waxpeer: item[1]["waxpeer"] )
                    end
                end
            rescue
                puts "Price Empire Job Failed..."
            end
        end
    end
end
  