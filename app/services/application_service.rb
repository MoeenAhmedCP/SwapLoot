# frozen_string_literal: true

class ApplicationService
  def report_api_error(response, backtrace)
    context = {
      source: 'api'
    }

    message = response_message(response)
    error = ApiError.new(message: message, backtrace: backtrace)
    reporter = Rails.error
    user = @steam_account.present? ? @steam_account&.user : @current_user
    reporter.subscribe(ErrorSubscriber.new(user))
    reporter&.report(error, handled: false, context: context)
  end

  private

  def response_message(response)
    return response.is_a?(Hash) ? response.map { |key, value| "#{key}: #{value}" }.join(', ') : response
  end
end
