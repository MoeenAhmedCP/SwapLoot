module TradeServiceConcern
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, only: %i[update]
    before_action :set_steam_account, :set_trade_service, only: %i[update]
  end

  private

  def set_trade_service
    @trade_service = TradeService.find params[:id]
  end

  def set_steam_account
    @steam_account = SteamAccount.find_by(id: params["steam_account_id"])
  end

  def trade_service_params
    params.require(:trade_service).permit(:buying_status, :selling_status, :selling_job_id, :buying_job_id, :price_cutting_job_id, :price_cutting_status)
  end
end
