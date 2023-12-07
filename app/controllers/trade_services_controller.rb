class TradeServicesController < ApplicationController
  include TradeServiceConcern
  require 'net/http'
  require 'uri'

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

    url = URI.parse("#{base_url}stopBuying?id=#{steam_account.id}&steamId=#{steam_id}&toggle=#{buying_status}")
    http = Net::HTTP.new(url.host, url.port)

    request = Net::HTTP::Get.new(url.path)
    response = http.request(request)
  end

  private

  def trigger_selling_service(steam_account)
    if trade_service_params[:selling_status] == SUCCESS
      selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
      price_cutting_job_id = PriceCuttingJob.perform_async(steam_account.id)
      @trade_service.update(selling_job_id: selling_job_id, price_cutting_job_id: price_cutting_job_id, price_cutting_status: true)
    else
      selling_job_id = @trade_service.selling_job_id
      delete_enqueued_job(selling_job_id)
      @trade_service.update(selling_job_id: nil)
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
