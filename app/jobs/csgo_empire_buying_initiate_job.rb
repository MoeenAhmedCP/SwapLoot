class CsgoEmpireBuyingInitiateJob < ApplicationJob
  queue_as :default

  # user as current user, items as csgo empire products, max_percentage as %age to add to item price, specific_price as max purchasing price
  def perform(user, items, max_percentage, specific_price)
    items.each do |item|
      begin
        CsgoEmpireBuyingJob.perform_later(user, item, max_percentage, specific_price)
      rescue StandardError => e
        logger.error "Error processing item #{item['market_name']}: #{e.message}"
        next
      end
    end
  end
end
