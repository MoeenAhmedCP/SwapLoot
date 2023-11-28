# frozen_string_literal: true

# app/controllers/concerns/trade_service_concern.rb
module TradeServiceConcern
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, only: %i[update]
    before_action :set_trade_service, :trigger_selling_service, only: %i[update]
  end

  private

  def set_trade_service
    @trade_service = TradeService.find params[:id]
  end

  def trigger_selling_service
    steam_account = @trade_service&.steam_account
    if trade_service_params[:selling_status] == SUCCESS
      params[:trade_service][:selling_job_id] = CsgoSellingJob.perform_async(steam_account&.id)
    else
      stop_selling_job
      params[:trade_service][:selling_job_id] = nil
    end
  end

  def stop_selling_job
    Sidekiq::Queue.new('default')&.find_job(@trade_service&.selling_job_id)&.delete
  end

  def trade_service_params
    params.require(:trade_service).permit(:buying_status, :selling_status, :selling_job_id, :buying_job_id)
  end
end
