class PriceEmpireSuggestedPriceJob
	include Sidekiq::Job
    
    def perform
        p "<---------------- Price Empire Suggested price Job Started ---------->"
        ActiveRecord::Base.transaction do
            begin
                response = HTTParty.get("https://api.pricempire.com/v3/items/prices?api_key=#{ENV['PRICEEMPIRE_API_KEY']}&currency=USD&sources=buff&sources=waxpeer&sources=buff_avg7")
                unless JSON.parse(response.body)["statusCode"] == 403
                    PriceEmpire.destroy_all
                    response.each do |item|
                        PriceEmpire.create!(item_name: item[0], liquidity: item[1]["liquidity"], buff: item[1]["buff"], waxpeer: item[1]["waxpeer"], buff_avg7: item[1]["buff_avg7"] )
                    end
                end
            rescue
                puts "Price Empire Job Failed..."
            end
        end
    end
end
  