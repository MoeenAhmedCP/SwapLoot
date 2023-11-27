class TradeServicesController < ApplicationController
  include TradeServiceConcern
  
  def update
    response = trigger_selling_service(@steam_account)
    @trade_service.update(trade_service_params)
  end

  private

  def trigger_selling_service(steam_account)
    if trade_service_params[:selling_status] == SUCCESS
      response = CsgoSellingJob.perform_async(steam_account.id)
      @trade_service.update(selling_job_id: response)
    else
      job_id = @trade_service.selling_job_id
      job = Sidekiq::Queue.new("default").find_job(job_id)
      job.delete if job
      @trade_service.update(selling_job_id: nil)
    end
  end
end
