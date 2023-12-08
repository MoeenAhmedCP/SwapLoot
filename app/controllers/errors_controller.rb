# frozen_string_literal: true

class ErrorsController < ApplicationController
  def index
    @errors = fetch_errors(params[:time_range], params[:error_source])
  end

  def show
    @error = Error.find(params[:id])
  end

  private

  def fetch_errors(time_range, error_source)
    errors = current_user.user_errors

    errors = case time_range
    when 'Last hour'
      errors.last_hour
    when 'Last day'
      errors.last_day
    when 'Last 7 days'
      errors.last_7_days
    when 'Last 14 days'
      errors.last_14_days
    when 'Last 1 month'
      errors.last_1_month
    else
      errors
    end

    errors = case error_source
    when 'Application'
      errors.application_errors
    when 'API'
      errors.api_errors
    else
      errors
    end

    return errors.newest_errors
  end
end
