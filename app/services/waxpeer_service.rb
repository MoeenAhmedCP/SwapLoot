class WaxpeerService
  include HTTParty

  BASE_URL = 'https://api.waxpeer.com/v1'

  def fetch_my_inventory
    params = {
      api: "6faf45a5a41fb178bc5bdb97ca1c96c001841d473cb8bac15f668262cdd9f5a1",
      skip: 0,
      game: "csgo"
    }
    response = self.class.get(BASE_URL + '/get-my-inventory', query: params)
  end
end
