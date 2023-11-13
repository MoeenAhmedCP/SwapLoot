class HomeController < ApplicationController
  before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance, 
                :fetch_active_trade, only: %i[index]

  def index
    @inventories = Inventory.all
  end

  private

  def fetch_csgo_empire_balance
    @csgo_empire_balance = CsgoempireService.new.fetch_balance
  end

  def fetch_csgo_market_balance
    @csgo_market_balance = MarketcsgoService.new.fetch_balance
  end

  def fetch_waxpeer_balance
    @waxpeer_balance = WaxpeerService.new.fetch_balance
  end

  def fetch_active_trade
    @active_trades = WaxpeerService.new.fetch_active_trade
  end
end
