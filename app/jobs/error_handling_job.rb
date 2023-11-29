# frozen_string_literal: true

class ErrorHandlingJob < ApplicationJob
  queue_as :errors_reporter

  def perform(error, handled, severity, context)
    Error.create!(
      message: error.message,
      backtrace: error.backtrace,
      error_type: error.exception.class.name,
      handled: handled,
      severity: severity.to_s,
      context: context
    )
  rescue => e
    logger.error "Error while creating error record: #{e.message}"
  end
end
