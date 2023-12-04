class SellingFiltersController < ApplicationController
  include SellingFilterConcern

  def edit
    respond_to(&:js)
  end

  def update
    message = I18n.t("selling_filters.update.#{@selling_filter.update(selling_filter_params) ? 'success' : 'failure'}")
    respond_to do |format|
      format.js { render json: { message: message, selling_id: @selling_filter.id }.to_json }
    end
  end
end
