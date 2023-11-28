class ApplicationController < ActionController::Base
  include ItemSoldHelper
  before_action :authenticate_user!

  rescue_from StandardError, with: :handle_error

  private

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
