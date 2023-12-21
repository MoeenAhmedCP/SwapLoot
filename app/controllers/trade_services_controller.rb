class TradeServicesController < ApplicationController
  include TradeServiceConcern
  require 'httparty'

  def update
    @trade_service.update(trade_service_params)
    trigger_selling_service(@steam_account) if trade_service_params[:selling_status]
    trigger_price_cutting(@steam_account) if trade_service_params[:price_cutting_status]
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
    if trade_service_params[:selling_status] == SUCCESS
      selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
      price_cutting_job_id = PriceCuttingJob.perform_async(steam_account.id)
      @trade_service.update(selling_job_id: selling_job_id, price_cutting_job_id: price_cutting_job_id, price_cutting_status: true)
      flash[:notice] = "Selling service started"
    else
      remove_items_listed_for_sale_response = RemoveItemListedForSaleJob.perform_async(steam_account.id)
      if remove_items_listed_for_sale_response == SUCCESS
        flash[:notice] = "Selling Terminated, Items have been removed from Listing.."
      else
        flash[:alert] = "Failed to remove items from Listing. Retrying in 2 minutes..."
        RemoveItemListedForSaleJob.perform_in(2.minutes, steam_account.id) # Schedule a retry after 2 minutes
      end
      selling_job_id = @trade_service.selling_job_id
      delete_enqueued_job(selling_job_id)
      @trade_service.update(selling_job_id: nil)
      flash[:notice] = "Selling service stopped"
    end
  end
  
  def trigger_price_cutting(steam_account)
    if trade_service_params[:price_cutting_status] == SUCCESS
      price_cutting_job_id = PriceCuttingJob.perform_async(steam_account.id)
      @trade_service.update(price_cutting_job_id: price_cutting_job_id, price_cutting_status: true)
    else
      price_cutting_job_id = @trade_service.price_cutting_job_id
      delete_enqueued_job(price_cutting_job_id)
      @trade_service.update(price_cutting_job_id: nil)
    end
  end
  
  def delete_enqueued_job(job_id)
    job = Sidekiq::Queue.new("default").find_job(job_id)
    job.delete if job
  end
end
