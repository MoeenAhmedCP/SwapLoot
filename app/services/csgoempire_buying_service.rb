class CsgoempireBuyingService
  WAXPEER_API_BASE_URL = ENV['WAXPEER_API_BASE_URL']

  def initialize(user)
    @current_user = user
    @active_steam_account = SteamAccount.find_by(active: true, user_id: @current_user.id)
    @headers = { 'Authorization' => "Bearer #{@active_steam_account&.csgoempire_api_key}" }
  end

  def buy_item(data, max_percentage, specific_price)
    price_check_result = check_price(data['market_name'], data['market_value'], max_percentage, specific_price)

    if price_check_result[:status] == 'success'
      response = self.class.post("/deposit/#{deposit_id}/bid", {
        headers: @headers,
        body: { 'bid_value' => bid_value }.to_json
      })

      if response.code == 200
        return { status: 'success', message: 'Item purchased successfully', purchase_details: JSON.parse(response.body) }
      else
        return { status: 'error', message: "HTTP Error: #{response.code} - #{response.message}" }
      end
    else
      return price_check_result
    end
  end

  private
  
  def check_price(name, price, max_percentage, specific_price)
    response = HTTParty.get("#{WAXPEER_API_BASE_URL}/suggested-price?game=csgo")

    if response.code == 200
      data = JSON.parse(response.body)
      item = data['items'].find { |item| item['name'] == name }
      
      if item
        if price <= (item['average'] * (100 - max_percentage) / 100.0) && price <= specific_price
          return { status: 'success', message: 'Price within acceptable range', item: item }
        else
          return { status: 'error', message: 'Price is too high', suggested_price: item['average'] * (100 - max_percentage) / 100.0 }
        end
      else
        return { status: 'error', message: 'Item not found' }
      end
    else
      return { status: 'error', message: 'API request failed' }
    end
  end
end
