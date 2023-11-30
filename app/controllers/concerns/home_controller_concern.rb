# frozen_string_literal: true

# app/controllers/concerns/home_controller_concern.rb
module HomeControllerConcern
  extend ActiveSupport::Concern
  included do
    before_action :fetch_active_trade, :fetch_item_listed_for_sale, :fetch_sold_items, only: [:index]
    before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance, :all_site_balance, only: [:refresh_balance]
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

  def all_site_balance
    unless current_user.active_steam_account
      @balance_data = []
      @csgo_empire_balance.pluck(:account_id).each do |account|
        steam_account = SteamAccount.find(account)
        e_balance = @csgo_empire_balance.find { |hash| hash[:account_id] == account }
        mark_balance = @csgo_market_balance.find { |hash| hash[:account_id] == account }
        wax_balance = @waxpeer_balance.find { |hash| hash[:account_id] == account }
        data_hash = {
          account_name: steam_account.unique_name.capitalize,
          csgo_empire_balance: e_balance[:balance].nil? ? '$0' : "#{e_balance[:balance]} coins",
          csgo_market_balance: mark_balance[:balance].nil? ? '$0' : "#{mark_balance[:balance]}",
          waxpeer_balance: wax_balance[:balance].nil? ? '$0' : "#{wax_balance[:balance]}"
        }
        @balance_data << data_hash
      end
      @balance_data
    end
  end

  def fetch_active_trade
    get_active_trade = CsgoempireService.new(current_user)
    @active_trades = get_active_trade.fetch_active_trade
    if @active_trades
      @deposits = @active_trades["data"]["deposits"]
      @deposits.map! { |item| item.merge("sellarbuy" => "deposit") }
      @withdrawls = @active_trades["data"]["withdrawals"]
      @withdrawls.map! { |item| item.merge("sellarbuy" => "withdrawl") } 
      @active_trades = @deposits + @withdrawls
    else
      @active_trades = []
    end
  end

  def fetch_sold_items
    waxpeer_service = WaxpeerService.new(current_user)
    waxpeer_service.fetch_sold_items

    csgo_service = CsgoempireService.new(current_user)
    csgo_service.fetch_deposit_transactions
  end

  def fetch_item_listed_for_sale
    @item_listed_for_sale_hash = fetch_csgoempire_item_listed_for_sale + fetch_waxpeer_item_listed_for_sale
  end

  def fetch_waxpeer_item_listed_for_sale
    waxpeer_service = WaxpeerService.new(current_user)
    item_listed_for_sale = waxpeer_service.fetch_item_listed_for_sale
    item_listed_for_sale_hash = item_listed_for_sale.map do |item|
      item.merge('site' => 'Waxpeer')
    end
  end

  def fetch_csgoempire_item_listed_for_sale
    csgoempire_service = CsgoempireService.new(current_user)
    item_listed_for_sale = csgoempire_service.fetch_item_listed_for_sale
    item_listed_for_sale_hash = item_listed_for_sale.map do |deposit|
      {
        'item_id' => deposit['item_id'],
        'market_name' => deposit['item']['market_name'],
        'price' => deposit['item']['market_value']* 0.614 * 1000,
        'site' => 'CsgoEmpire',
        'date' => Time.parse(deposit['item']['updated_at']).strftime('%d/%B/%Y')
      }
    end
  end

end
