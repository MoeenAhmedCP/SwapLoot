class ServicesController < ApplicationController
    def index
        @steam_accounts =  SteamAccount.all
    end

    def trigger_service
        redirect_to services_path
    end
  end
  