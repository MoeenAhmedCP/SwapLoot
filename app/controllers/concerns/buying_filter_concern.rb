module BuyingFilterConcern
    extend ActiveSupport::Concern
  
    included do
      before_action :set_buying_filter, only: %i[edit update]
    end
  
    private
  
    def set_buying_filter
      @buying_filter = BuyingFilter.find(params[:id])
    end
  
    def buying_filter_params
      params.require(:buying_filter)
            .permit(:min_percentage, :max_price, :min_price, :steam_account_id)
    end
  end
  