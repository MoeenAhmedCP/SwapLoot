# frozen_string_literal: true

# app/controllers/concerns/home_controller_concern.rb
module HomeControllerConcern
  extend ActiveSupport::Concern
  included do
    before_action :fetch_items_bid_history, :fetch_item_listed_for_sale, only: [:index]
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
          account_name: steam_account.unique_name.capitalize
        }
        data_hash.merge!(csgo_empire_balance: "#{e_balance[:balance]} coins") unless e_balance&.dig(:balance).nil?
        data_hash.merge!(csgo_market_balance: "#{mark_balance[:balance]}") unless mark_balance&.dig(:balance).nil?
        data_hash.merge!(waxpeer_balance: "#{wax_balance[:balance]}") unless wax_balance&.dig(:balance).nil?
        @balance_data << data_hash
      end
      flash[:alert] = 'Something went wrong with fetch balance issue' if @balance_data.empty? && current_user.steam_accounts.present?
      @balance_data
    end
  end

  def fetch_items_bid_history
    csgoempire_service = CsgoempireService.new(current_user)
    items_bid_history = csgoempire_service.items_bid_history
    if items_bid_history.present?
      if items_bid_history.is_a?(Array) && items_bid_history.first.is_a?(Hash) && items_bid_history.first[:success] == false
        @auction_items_hash = []
      else
        @auction_items_hash = items_bid_history&.map do |auction_item|
          {
            'item_id' => auction_item['id'],
            'market_name' => auction_item['market_name'],
            'price' => ((auction_item['auction_highest_bid'].to_f / 100) * 0.614).round(2),
            'site' => 'CsgoEmpire',
            'date' => Time.parse(auction_item['published_at']).strftime('%d/%B/%Y')
          }
        end
      end
    else
      @auction_items_hash = []
    end
    @auction_items_hash
  end

  def fetch_item_listed_for_sale
    steam_account_ids = @active_steam_account.respond_to?(:each) ? @active_steam_account.map(&:id) : [@active_steam_account.id]
    @item_listed_for_sale_hash = ListedItem.where(steam_account_id: steam_account_ids)
  end

  def fetch_waxpeer_item_listed_for_sale
    waxpeer_service = WaxpeerService.new(current_user)
    item_listed_for_sale = waxpeer_service.fetch_item_listed_for_sale
    if item_listed_for_sale.present? && item_listed_for_sale.first[:success].present?
      item = item_listed_for_sale.first
      flash[:alert] = "Error: #{item[:msg]}, for waxpeer fetch listed items for sale"
      []
    else
      item_listed_for_sale_hash = item_listed_for_sale.map do |item|
        item.merge('site' => 'Waxpeer')
      end
    end
  end
end
