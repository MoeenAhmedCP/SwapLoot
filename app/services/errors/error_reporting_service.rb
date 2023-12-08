# frozen_string_literal: true

class Errors::ErrorReportingService
  attr_reader :error, :handled, :severity, :context, :current_user

  def initialize(error, handled, severity, context, user)
    @error = error
    @handled = handled
    @severity = severity
    @context = context
    @current_user = user
  end

  def call
    Error.create!(
      message: @error&.message,
      backtrace: @error&.backtrace&.reject{ |e| e.include? '/gems/ruby' },
      error_type: @error&.exception&.class&.name,
      handled: @handled,
      severity: @severity.to_s,
      context: context_details,
      user: @current_user
    )
  end

  private

  def context_details
    {
      'user_id' => @context[:user_id].to_s,
      'user_email' => @context[:user_email].to_s,
      'controller' => @context[:controller]&.class&.name,
      'action' => @context[:controller]&.action_name,
      'url' => @context[:url],
      'source' => @context[:source] || 'application',
    } if @context
  end
end
