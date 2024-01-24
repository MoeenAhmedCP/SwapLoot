class ServicesController < ApplicationController
  before_action :set_steam_account, only: %i[index]

  def index; end

  private

  def set_steam_account
    @steam_accounts = current_user.steam_accounts.where(valid_account: true)
  end
end
