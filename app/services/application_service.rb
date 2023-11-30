# frozen_string_literal: true

class ApplicationService
  def report_api_error(response)
    context = {
      user_id: @current_user&.id,
      user_email: @current_user&.email,
      source: 'api'
    }

    error = ApiError.new(message: response&.keys&.at(1), backtrace: [self&.class&.name])
    reporter = Rails.error
    reporter.subscribe(ErrorSubscriber.new)
    reporter&.report(error, handled: false, context: context)
  end
end
