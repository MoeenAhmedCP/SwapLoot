class SellingFiltersController < ApplicationController
  include SellingFilterConcern

  def edit
    respond_to(&:js)
  end

  def update
    message = I18n.t("selling_filters.update.#{@selling_filter.update(selling_filter_params) ? 'success' : 'failure'}")
    respond_to do |format|
      format.js do
        if message.include?("success")
          flash[:notice] = "Selling filter updated successfully."
        else
          flash[:alert] = "Something went wrong"
        end
        render json: { message: message, selling_id: @selling_filter.id }.to_json
      end
    end
  end
end
