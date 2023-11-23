# frozen_string_literal: true

# app/controllers/concerns/trade_service_concern.rb
module TradeServiceConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_trade_service, only: %i[update]
    skip_before_action :verify_authenticity_token, only: %i[update]
  end

  private

  def set_trade_service
    @trade_service = TradeService.find params[:id]
  end

  def trade_service_params
    params.require(:trade_service).permit(:buying_status, :selling_status, :selling_job_id, :buying_job_id)
  end
end
