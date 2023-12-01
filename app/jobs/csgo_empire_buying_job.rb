class CsgoEmpireBuyingJob < ApplicationJob
  queue_as :csgo_buying_item

  # user as current user, item as csgo empire product data, max_percentage as %age to add to item price, specific_price as max purchasing price
  def perform(user, item, max_percentage, specific_price, event_name = '')
    if event_name == 'auction_update'
      response = CsgoempireBuyingService.new(user).update_bid(item, max_percentage, specific_price)
    else
      response = CsgoempireBuyingService.new(user).buy_item(item, max_percentage, specific_price)
    end
    logger.info "CsgoempireBuyingService#buy_item response: #{response.inspect}"
  rescue StandardError => e
    logger.error "Error processing item #{item['market_name']}: #{e.message}"
  end
end
