# frozen_string_literal: true

class ErrorSubscriber
  def initialize(user)
    @current_user = user
  end

  def report(error, handled:, severity:, context:)
    Errors::ErrorReportingService.new(error, handled, severity, context, @current_user).call
  end
end
