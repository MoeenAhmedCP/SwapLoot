class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :admin_controller?
  before_action :set_steam_accounts
  before_action :active_steam_account

  rescue_from StandardError, with: :handle_error

  private

  def admin_controller?
    request.url.include?("admin")
  end

  def set_steam_accounts
    @steam_accounts = current_user&.steam_accounts
  end

  def active_steam_account
    @active_steam_account ||= current_user.active_steam_account.presence || current_user.steam_accounts if current_user.present?
  end

  def handle_error(error)
    context = {
      user_id: current_user&.id,
      user_email: current_user&.email,
      source: 'application',
      url: request&.url
    }

    reporter = Rails.error
    reporter.subscribe(ErrorSubscriber.new)
    reporter&.report(error, handled: false, context: context)
    
    raise error
  end
end
