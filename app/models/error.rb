# frozen_string_literal: true

class Error < ApplicationRecord
  scope :newest_errors, -> { order(created_at: :desc) }
  scope :last_hour, -> { where('created_at >= ?', 1.hour.ago) }
  scope :last_day, -> { where('created_at >= ?', 1.day.ago) }
  scope :last_7_days, -> { where('created_at >= ?', 7.days.ago) }
  scope :last_14_days, -> { where('created_at >= ?', 14.days.ago) }
  scope :last_1_month, -> { where('created_at >= ?', 1.month.ago) }
  scope :application_errors, -> { where("context->>'source' = ?", 'application') }
  scope :api_errors, -> { where("context->>'source' = ?", 'api') }
end
