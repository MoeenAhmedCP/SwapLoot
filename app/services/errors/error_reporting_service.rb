# frozen_string_literal: true

class Errors::ErrorReportingService
  attr_reader :error, :handled, :severity, :context

  def initialize(error, handled, severity, context)
    @error = error
    @handled = handled
    @severity = severity
    @context = context
  end

  def call
    ErrorHandlingJob.perform_later(error, handled, severity, context)
  end
end
