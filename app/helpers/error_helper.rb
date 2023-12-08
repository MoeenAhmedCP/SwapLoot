# frozen_string_literal: true

module ErrorHelper
  def error_message(message)
    truncate(message, length: 50)
  end

  def error_severity_class(severity)
    if severity == 'error'
      'bg-red-500'
    elsif severity == 'warning'
      'bg-yellow-500'
    else
      'bg-blue'
    end
  end

  def error_handled(handled)
    handled ? 'Handled' : 'Unhandled'
  end

  def error_handled_class(handled)
    handled ? 'text-green-500' : 'text-orange-600'
  end

  def error_reported_duration(created_at)
    "#{time_ago_in_words(created_at)} ago"
  end

  def error_reported_at(created_at)
    created_at.strftime("%B %e, %Y %l:%M %p %Z")
  end

  def error_status_btn(handled)
    handled ? 'Mark as Unresolved' : 'Mark as Resolved'
  end

  def error_status_btn_class(handled)
    handled ? 'bg-red-500 hover:bg-red-600' : 'bg-green-500 hover:bg-green-600'
  end

  def error_controller_action(error)
    if error.controller.present?
      "#{error.controller}##{error.action}"
    end
  end

  def error_source_class(source)
    source == 'api' ? 'bg-indigo-600' : 'bg-amber-600'
  end

  def filters_by_time
    ['All', 'Last hour', 'Last day', 'Last 7 days', 'Last 14 days', 'Last 1 Month']
  end

  def filters_by_error_source
    ['All', 'Application', 'API']
  end

  def filters_by_level
    ['All', 'Error', 'Warning', 'Info']
  end

  def filters_by_handled
    ['All', 'Resolved', 'Unresolved']
  end
end
