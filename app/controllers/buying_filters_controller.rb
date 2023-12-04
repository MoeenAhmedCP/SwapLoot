class BuyingFiltersController < ApplicationController
    include BuyingFilterConcern
  
    def edit
      respond_to(&:js)
    end
  
    def update
      message = I18n.t("buying_filters.update.#{@buying_filter.update(buying_filter_params) ? 'success' : 'failure'}")
      respond_to do |format|
        format.js { render json: { message: message, buying_id: @buying_filter.id }.to_json }
      end
    end
  end
  