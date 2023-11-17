class BuyingService

  def check_price(name, price, max_percentage, specific_price)
    response = HTTParty.get("https://api.waxpeer.com/v1/suggested-price?game=csgo")

    if response.code == 200
      data = JSON.parse(response.body)
      item = data["items"].find { |item| item["name"] == name }
      if item
        if price <= (item["average"] * (100 - max_percentage) / 100.0) && price <= specific_price
          result = true
        else
          result = false
        end
      else
        result = "Item not found"
      end
    else
      result = "API request failed"
    end
    result
  end

  def buy_process(name, price, deposit_id, api_key, bid_value, max_percentage, specific_price)
    if check_price(name, price, max_percentage, specific_price)
      response = self.class.post("/deposit/#{deposit_id}/bid", {
        headers: {
          'Authorization' => "Bearer #{api_key}",
          'Content-Type' => 'application/json'
        },
        body: { 'bid_value' => bid_value }.to_json
      })

      if response.code == 200
        return JSON.parse(response.body)
      else
        return "HTTP Error: #{response.code} - #{response.message}"
      end
    end
  end

end