# frozen_string_literal: true

# app/controllers/concerns/home_controller_concern.rb
module HomeControllerConcern
  extend ActiveSupport::Concern
  included do
    before_action :csgoempire_items_data, only: %i[index]
    before_action :fetch_csgo_empire_balance, :fetch_csgo_market_balance, :fetch_waxpeer_balance, :all_site_balance, only: %i[refresh_balance]
    # before_action :csgoempire_items_data, only: %i[fetch_active_trade fetch_csgo_empire_all_items_data]
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
          csgo_empire_balance: e_balance&.dig(:balance).nil? ? "" : "#{e_balance[:balance]} coins",
          csgo_market_balance: mark_balance&.dig(:balance).nil? ? "" : "#{mark_balance[:balance]}",
          waxpeer_balance: wax_balance&.dig(:balance).nil? ? "" : "#{wax_balance[:balance]}"
        }
        @balance_data << data_hash
      end
      flash[:alert] = "Something went wrong with fetch balance issue." if @balance_data.empty? && current_user.steam_accounts.present?
      @balance_data
    end
  end

  def fetch_active_trade
    @filtered_active_trades_for_csgoempire = @items_listed_for_sale["withdrawals"].map do |deposit|
      {
        'item_id' => deposit['item_id'],
        'market_name' => deposit['item']['market_name'],
        'price' => deposit['item']['market_value'] * 0.614 * 1000,
        'site' => 'CsgoEmpire',
        'date' => Time.parse(deposit['created_at']).strftime('%d/%B/%Y')
      }
    end
    return @filtered_active_trades_for_csgoempire
  end

  def fetch_csgo_empire_all_items_data
    @filtered_items_listed_for_sale_csgoempire = @items_listed_for_sale["deposits"].map do |deposit|
      {
        'item_id' => deposit['item_id'],
        'market_name' => deposit['item']['market_name'],
        'price' => deposit['item']['market_value'] * 0.614 * 1000,
        'site' => 'CsgoEmpire',
        'date' => Time.parse(deposit['item']['updated_at']).strftime('%d/%B/%Y')
      }
    end
    @item_listed_for_sale_hash = @filtered_items_listed_for_sale_csgoempire
    @item_listed_for_sale_hash += fetch_waxpeer_item_listed_for_sale
    return @item_listed_for_sale_hash.flatten
  end

  def fetch_waxpeer_item_listed_for_sale
    waxpeer_service = WaxpeerService.new(current_user)
    item_listed_for_sale = waxpeer_service.fetch_item_listed_for_sale
    if item_listed_for_sale.present? && item_listed_for_sale.first[:success].present?
      item = item_listed_for_sale.first
      flash[:alert] = "Error: #{item[:msg]}, for waxpeer fetch listed items for sale"
      []
    else
      @item_listed_for_sale_hash = item_listed_for_sale.map do |item|
        item.merge('site' => 'Waxpeer')
      end
    end
  end

  def csgoempire_items_data(filter_value = nil)
    csgoempire_service = CsgoempireService.new(current_user)
    item_listed_for_sale = csgoempire_service.fetch_items_data
    if item_listed_for_sale[0]["data"]["withdrawals"].empty? && item_listed_for_sale[0]["data"]["deposits"].empty?
      []
    else
      @items_listed_for_sale = item_listed_for_sale[0]["data"]
    end
    unless filter_value
      fetch_active_trade
      fetch_csgo_empire_all_items_data
    end
    fetch_active_trade if filter_value == "active_trades"
    fetch_csgo_empire_all_items_data if filter_value == "listed_items_for_sale"
  end
end
