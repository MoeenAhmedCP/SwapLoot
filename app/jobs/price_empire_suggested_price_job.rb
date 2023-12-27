class PriceEmpireSuggestedPriceJob
	include Sidekiq::Job
    
    def perform
        p "<---------------- Price Empire Suggested price Job Started ---------->"
        ActiveRecord::Base.transaction do
            PriceEmpire.destroy_all
            begin
                response = HTTParty.get("https://api.pricempire.com/v3/items/prices?api_key=#{ENV['PRICEEMPIRE_API_KEY']}&currency=USD&sources=buff&sources=waxpeer&sources=csgoempire")
                response.each do |item|
                    PriceEmpire.create!(item_name: item[0], liquidity: item[1]["liquidity"], buff: item[1]["buff"], waxpeer: item[1]["waxpeer"] )
                end
            rescue
                PriceEmpireSuggestedPriceJob.perform_in(2.minutes)
            end
        end
    end
end
  