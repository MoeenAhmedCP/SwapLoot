# frozen_string_literal: true

# app/controllers/concerns/selling_filter_concern.rb
module SellingFilterConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_selling_filter, only: %i[edit update]
  end

  private

  def set_selling_filter
    @selling_filter = SellingFilter.find(params[:id])
  end

  def selling_filter_params
    params.require(:selling_filter)
          .permit(:min_profit_percentage, :undercutting_price_percentage, :undercutting_interval, :steam_account_id)
  end
end
