class TradeServicesController < ApplicationController
  include TradeServiceConcern
  include DeleteEnqueuedJobsConcern
  require 'httparty'

  def update
    @trade_service.update(trade_service_params)
    trigger_selling_service(@steam_account) if trade_service_params[:selling_status]
    send_status(@trade_service.steam_account, trade_service_params[:buying_status] ) if trade_service_params[:buying_status].present? 
  end

  def send_status(steam_account, status)
    base_url = ENV['NODE_TOGGLE_SERVICE_URL']
    steam_id = steam_account.steam_id
    buying_status = status

    url = "#{base_url}/toggleBuying"
    params = { id: steam_account.id, steamId: steam_id, toggle: buying_status }

    response = HTTParty.post(url, query: params)
    if status == "true"
      flash[:notice] = "Buying service started"
    else
      flash[:notice] = "Buying service stopped"
    end
  end

  private

  def trigger_selling_service(steam_account)
    type = params["trade_service"]["service_name"] 
    case type
    when "csgoempire"
      if trade_service_params[:selling_status] == SUCCESS
        selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
        price_cutting_job_id = PriceCuttingJob.perform_in(steam_account.selling_filters.csgoempire_filter.undercutting_interval.minutes, steam_account.id)
        @trade_service.update(selling_job_id: selling_job_id, price_cutting_job_id: price_cutting_job_id)
        flash[:notice] = "CSGOEmpire Selling service started."
      else
        RemoveItemListedForSaleJob.perform_async(steam_account.id)
        delete_enqueued_job(@trade_service&.price_cutting_job_id) if @trade_service&.price_cutting_job_id 
        delete_enqueued_job(@trade_service&.selling_job_id) if @trade_service&.selling_job_id
        @trade_service.update(selling_job_id: nil, price_cutting_job_id: nil) if @trade_service&.price_cutting_job_id && @trade_service&.selling_job_id
        flash[:notice] = "CSGOEmpire Selling service stopped."
      end
    when "waxpeer"
      if trade_service_params[:selling_status] == SUCCESS
        selling_job_id = WaxpeerSellingJob.perform_async(steam_account.id)
        price_cutting_job_id = WaxpeerPriceCuttingJob.perform_in(steam_account.selling_filters.waxpeer_filter.undercutting_interval.minutes, steam_account.id)
        @trade_service.update(selling_job_id: selling_job_id, price_cutting_job_id: price_cutting_job_id)
        flash[:notice] = "Waxpeer Selling service started."
      else
        RemoveWaxpeerItemsFromListingJob.perform_async(steam_account.id)
        delete_enqueued_job(@trade_service&.price_cutting_job_id) if @trade_service&.price_cutting_job_id 
        delete_enqueued_job(@trade_service&.selling_job_id) if @trade_service&.selling_job_id
        @trade_service.update(selling_job_id: nil, price_cutting_job_id: nil) if @trade_service&.price_cutting_job_id && @trade_service&.selling_job_id
        flash[:notice] = "Waxpeer Selling service stopped."
      end
    when "market_csgo"
      # if trade_service_params[:selling_status] == SUCCESS
      #   selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
      #   price_cutting_job_id = PriceCuttingJob.perform_in(steam_account.selling_filters.market_csgo_filter.undercutting_interval.minutes, steam_account.id)
      #   @trade_service.update(selling_job_id: selling_job_id, price_cutting_job_id: price_cutting_job_id)
      #   flash[:notice] = "Selling service started."
      # else
      #   RemoveItemListedForSaleJob.perform_async(steam_account.id)
      #   delete_enqueued_job(@trade_service&.price_cutting_job_id) if @trade_service&.price_cutting_job_id 
      #   delete_enqueued_job(@trade_service&.selling_job_id) if @trade_service&.selling_job_id
      #   @trade_service.update(selling_job_id: nil, price_cutting_job_id: nil) if @trade_service&.price_cutting_job_id && @trade_service&.selling_job_id
      #   flash[:notice] = "Selling service stopped."
      # end
    end
  end
end


