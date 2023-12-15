class SoldItemsController < ApplicationController

  before_action :fetch_sold_items , only: [:index]
  def index
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
    steam_account = !@active_steam_account.respond_to?(:each) ? current_user.active_steam_account : current_user.steam_accounts
    @items_sold = SoldItem.where(steam_account: steam_account).paginate(page: params[:page], per_page: 15)
  end

  def fetch_sold_items
    begin
      waxpeer_service = WaxpeerService.new(current_user)
      waxpeer_service.fetch_sold_items

      csgo_service = CsgoempireService.new(current_user)
      csgo_service.fetch_deposit_transactions
    rescue => exception
      puts "exception in fetch sold items API #{exception}"
    end
  end
end