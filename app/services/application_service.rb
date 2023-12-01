# frozen_string_literal: true

class ApplicationService
  def report_api_error(message, backtrace)
    context = {
      user_id: @current_user&.id,
      user_email: @current_user&.email,
      source: 'api'
    }

    error = ApiError.new(message: message, backtrace: backtrace)
    reporter = Rails.error
    reporter.subscribe(ErrorSubscriber.new)
    reporter&.report(error, handled: false, context: context)
  end
end
