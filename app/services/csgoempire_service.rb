class CsgoempireService
  include HTTParty

  BASE_URL = 'https://csgoempire.com/api/v2'

  def fetch_my_inventory
    headers = { 'Authorization' => "Bearer 812bb8bd18af87a449b183c6075117f1" }
    response = self.class.get(BASE_URL + '/trading/user/inventory', headers: headers)
  end
end
