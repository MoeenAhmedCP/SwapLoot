# frozen_string_literal: true

class ErrorSubscriber
  def report(error, handled:, severity:, context:)
    Errors::ErrorReportingService.new(error, handled, severity, context).call
  end
end
