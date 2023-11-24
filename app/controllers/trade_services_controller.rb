# frozen_string_literal: true

# Controller responsible for managing trade services.
class TradeServicesController < ApplicationController
  include TradeServiceConcern

  def update
    @trade_service.update(trade_service_params)
  end
end
