# frozen_string_literal: true

class ApplicationService
  def report_api_error(response, backtrace)
    context = {
      user_id: @current_user&.id,
      user_email: @current_user&.email,
      source: 'api'
    }

    message = response_message(response)

    error = ApiError.new(message: message, backtrace: backtrace)
    reporter = Rails.error
    reporter.subscribe(ErrorSubscriber.new)
    reporter&.report(error, handled: false, context: context)
  end

  private

  def response_message(response)
    return response.map { |key, value| "#{key}: #{value}" }.join(', ')
  end
end
