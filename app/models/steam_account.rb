class SteamAccount < ApplicationRecord
  scope :active_accounts, -> { where(active: true) }
  
  belongs_to :user
  has_one :trade_service, dependent: :destroy
  has_one :selling_filter, dependent: :destroy
  has_one :buying_filter, dependent: :destroy
  has_many :sold_items, dependent: :destroy
  validates :steam_id, uniqueness: true
  validates :unique_name, uniqueness: true
  validates :csgoempire_api_key, uniqueness: true

  before_save :check_api_keys

  def check_api_keys
    if csgoempire_api_key.present?
      csgo_response = CsgoempireService.get("#{CSGO_EMPIRE_BASE_URL}/metadata/socket", headers: { 'Authorization' => "Bearer #{csgoempire_api_key}" })
      if csgo_response['invalid_api_token'].present?
        self.csgoempire_api_key = nil
      end
    end

    if waxpeer_api_key.present?
      waxpeer_response = WaxpeerService.get("#{WAXPEER_BASE_URL}/user", query: { api: waxpeer_api_key })
      if waxpeer_response['msg'] == 'wrong api'
        self.waxpeer_api_key = nil
      end
    end

    if market_csgo_api_key.present?
      marketcsgo_response = MarketcsgoService.get("#{MARKET_CSGO_BASE_URL}/get-money", query: { key: market_csgo_api_key })
      if marketcsgo_response['error'] == 'Bad KEY'
        self.market_csgo_api_key = nil
      end
    end
  end
end
