class SoldItemsController < ApplicationController

  # before_action :fetch_sold_items , only: [:index]
  def index
    @steam_accounts = SteamAccount.where(user_id: current_user.id)
<<<<<<< HEAD
    steam_account = !@active_steam_account.respond_to?(:each) ? current_user.active_steam_account : current_user.steam_accounts
    @items_sold = SoldItem.where(steam_account: steam_account).paginate(page: params[:page], per_page: 15)
=======
    @sold_items_history = SoldItemHistory.all
    @items_sold = !@active_steam_account.respond_to?(:each) ? SoldItem.where(steam_account: current_user.active_steam_account) : SoldItem.where(steam_account: current_user.steam_accounts)
>>>>>>> f12aec7 (Sold Item History Done)
  end

  def fetch_sold_items
    begin
      waxpeer_service = WaxpeerService.new(current_user)
      waxpeer_service.fetch_sold_items

      csgo_service = CsgoempireService.new(current_user)
      csgo_service.fetch_deposit_transactions
      @sold_items_history = SoldItemHistory.all
      respond_to do |format|
        format.js
      end
    rescue => exception
      puts "exception in fetch sold items API #{exception}"
    end
  end
end