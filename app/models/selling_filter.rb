# frozen_string_literal: true

# This class represents a Selling filter and is associated with a Steam account.
class SellingFilter < ApplicationRecord
  belongs_to :steam_account
  after_update :set_service_status
  after_update :stop_selling_job

  def set_service_status
    service_type = self.class.name.gsub(/Filter$/, '').downcase
    steam_account&.trade_service&.update("#{service_type}_status".to_sym => false,
                                         "#{service_type}_job_id".to_sym => '')
  end

  def stop_selling_job
    trade_service = steam_account&.trade_service
    job_id = trade_service&.selling_job_id
    if job_id
      job = Sidekiq::Queue.new('default').find_job(job_id)
      job&.delete
      trade_service.update(selling_job_id: nil)
    end
    trade_service.update(selling_status: false)
  end
end
