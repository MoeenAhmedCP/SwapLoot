class BuyingFiltersController < ApplicationController
  include BuyingFilterConcern
  require 'httparty'

  def edit
    respond_to(&:js)
  end

  def update
    message = I18n.t("buying_filters.update.#{@buying_filter.update(buying_filter_params) ? 'success' : 'failure'}")
    if @buying_filter.steam_account.trade_service.buying_status == true
      @buying_filter.steam_account.trade_service.update(buying_status: false)
      base_url = ENV['NODE_TOGGLE_SERVICE_URL']
      steam_account = @buying_filter.steam_account
      buying_status = status
      url = "#{base_url}/toggleBuying"
      params = { id: steam_account.id, steamId: steam_account.steam_id, toggle: false }
      response = HTTParty.post(url, query: params)
    end
    respond_to do |format|
      format.js { render json: { message: message, buying_id: @buying_filter.id }.to_json }
    end
  end
end
  