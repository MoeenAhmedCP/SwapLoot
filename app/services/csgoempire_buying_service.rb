class BuyingService

  def check_price(name, price, maximun_percentage, specific_price)
    response = HTTParty.get(WAXPEER_BASE_URL + '/suggested-price?game=csgo')
    if response.code == SUCCESS_CODE
      data = JSON.parse(response.body)
      item = data["items"].find { |item| item["name"] == name }
      if item
        if price <= calculate_price_criteria(item["average"], maximun_percentage, price, specific_price)
          result = true
        else
          result = false
        end
      else
        result = ITEM_NOT_FOUND
      end
    else
      result = API_FAILED
    end
    result
  end

  def calculate_price_criteria(average_price, maximun_percentage, price, specific_price)
    (average_price * (100 - maximun_percentage) / 100.0) && price <= specific_price
  end

  def buy_process(name, price, deposit_id, api_key, bid_value, maximun_percentage, specific_price)
    if check_price(name, price, maximun_percentage, specific_price)
      response = self.class.post("/deposit/#{deposit_id}/bid", {
        headers: {
          'Authorization' => "Bearer #{api_key}",
          'Content-Type' => 'application/json'
        },
        body: { 'bid_value' => bid_value }.to_json
      })

      if response.code == SUCCESS_CODE
        return JSON.parse(response.body)
      else
        return "HTTP Error: #{response.code} - #{response.message}"
      end
    end
  end

end