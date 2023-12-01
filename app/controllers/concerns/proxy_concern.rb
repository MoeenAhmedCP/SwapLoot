# frozen_string_literal: true

# app/controllers/concerns/proxy_concern.rb
module ProxyConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_proxy, only: %i[edit update destroy]
  end

  private

  def set_proxy
    @proxy = Proxy.find(params[:id])
  end

  def proxy_params
    params.require(:proxy).permit(:ip, :port, :username, :password, :steam_account_id)
  end
end
