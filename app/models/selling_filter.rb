# frozen_string_literal: true

# This class represents a Selling filter and is associated with a Steam account.
class SellingFilter < ApplicationRecord
  belongs_to :steam_account
  after_update :stop_selling_job
  after_update :set_service_status

  def set_service_status
    service_type = self.class.name.gsub(/Filter$/, '').downcase
    steam_account&.trade_service&.update("#{service_type}_status".to_sym => false,
                                         "#{service_type}_job_id".to_sym => '')
  end

  def stop_selling_job
    job_id = steam_account&.trade_service&.selling_job_id
    return if job_id.blank?

    job = Sidekiq::Queue.new('default').find_job(job_id)
    job&.delete
  end
end
