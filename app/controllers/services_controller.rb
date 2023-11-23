class ServicesController < ApplicationController
  def index
    @steam_accounts = current_user.steam_accounts
  end

  def trigger_service
    redirect_to services_path
  end
end
