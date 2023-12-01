class CsgoempireBuyingService < ApplicationService
  WAXPEER_API_BASE_URL = WAXPEER_BASE_URL
  CSGO_EMPIRE_API_BASE_URL = CSGO_EMPIRE_BASE_URL
  CSGO_EMPIRE_BID_FACTOR = 0.1

  def initialize(user)
    @active_steam_account = SteamAccount.find_by(active: true, user_id: user.id)
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}", 'Content-Type' => 'application/json' }
  end

  def buy_item(data, max_percentage, specific_price)
    price_check_result = check_price(data['market_name'], data['market_value'], max_percentage, specific_price)

    if price_check_result[:status] == 'success'
      bid_value = data['market_value'] + (data['market_value'] * CSGO_EMPIRE_BID_FACTOR.to_f / 100.0).round(2)
      response = place_bid(data['id'], bid_value)

      if response.code == 200
        BidItem.create(deposit_id: data['id'], item_name: data['market_name'])
        return { status: 'success', message: 'Bid placed successfully', purchase_details: JSON.parse(response.body) }
      else
        report_api_error("HTTP Error: #{response.code} - #{response.message}", [self&.class&.name, __method__.to_s])
        return { status: 'error', message: "HTTP Error: #{response.code} - #{response.message}" }
      end
    else
      return price_check_result
    end
  end

  def update_bid(data, max_percentage, specific_price)
    bid_item = BidItem.find_by(deposit_id: data['id'])
    price_check_result = check_price(bid_item.item_name, data['auction_highest_bid'], max_percentage, specific_price)

    if price_check_result[:status] == 'success'
      bid_value = data['auction_highest_bid'] + (data['auction_highest_bid'] * CSGO_EMPIRE_BID_FACTOR.to_f / 100.0).round(2)
      response = place_bid(data['id'], bid_value)

      if response.code == 200
        { status: 'success', message: 'Bid updated successfully', purchase_details: JSON.parse(response.body) }
      else
        { status: 'error', message: "HTTP Error: #{response.code} - #{response.message}" }
      end
    else
      price_check_result
    end
  end

  private
  
  def check_price(name, price, max_percentage, specific_price)
    response = HTTParty.get("#{WAXPEER_API_BASE_URL}/suggested-price?game=csgo")

    if response.code == 200
      data = JSON.parse(response.body)
      item = data['items'].find { |item| item['name'] == name }
      
      if item
        suggested_price = item['average'] * (100 - max_percentage) / 100.0

        if price <= suggested_price && price <= specific_price
          return { status: 'success', message: 'Price within acceptable range', item: item }
        else
          return { status: 'error', message: 'Price is too high', suggested_price: suggested_price }
        end
      else
        return { status: 'error', message: 'Item not found' }
      end
    else
      return { status: 'error', message: 'API request failed' }
    end
  end

  def place_bid(deposit_id, bid_value)
    url = "#{CSGO_EMPIRE_API_BASE_URL}/trading/deposit/#{deposit_id}/bid"

    HTTParty.post(
      url,
      headers: @headers,
      body: {
        bid_value: bid_value.to_i
      }.to_json
    )
  end
end
