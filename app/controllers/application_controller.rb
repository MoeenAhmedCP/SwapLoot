class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_steam_accounts

  rescue_from StandardError, with: :handle_error

  private

  def set_steam_accounts
    @steam_accounts = current_user.steam_accounts
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
