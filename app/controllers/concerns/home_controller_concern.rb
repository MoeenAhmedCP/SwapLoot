# frozen_string_literal: true

# app/controllers/concerns/home_controller_concern.rb
module HomeControllerConcern
  extend ActiveSupport::Concern
  included do
    before_action :fetch_active_trade, :fetch_waxpeer_item_listed_for_sale, :fetch_sold_items, only: [:index]
    before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance, only: [:refresh_balance]
  end

  private

  def fetch_csgo_empire_balance
    csgo_service = CsgoempireService.new(current_user)
    @csgo_empire_balance = csgo_service.fetch_balance
  end

  def fetch_csgo_market_balance
    marketcsgo_service = MarketcsgoService.new(current_user)
    @csgo_market_balance = marketcsgo_service.fetch_balance
  end

  def fetch_waxpeer_balance
    waxpeer_service = WaxpeerService.new(current_user)
    @waxpeer_balance = waxpeer_service.fetch_balance
  end

  def fetch_active_trade
    @active_trades = []
  end

  def fetch_sold_items
    waxpeer_service = WaxpeerService.new(current_user)
    @items_sold = waxpeer_service.fetch_sold_items
  end

  def fetch_waxpeer_item_listed_for_sale
    waxpeer_service = WaxpeerService.new(current_user)
    item_listed_for_sale = waxpeer_service.fetch_item_listed_for_sale
    @item_listed_for_sale_hash = item_listed_for_sale.map do |item|
      item.merge('site' => 'Waxpeer')
    end
  end
end
