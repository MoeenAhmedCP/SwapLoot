class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  include ErrorHandler

  rescue_from StandardError, with: :handle_error

  private

  def handle_error(error)
    reporter = Rails.error
    reporter.subscribe(ErrorSubscriber.new)
    reporter&.report(error, handled: false, context: { user_id: current_user&.id, user_email: current_user&.email })
  end
end
