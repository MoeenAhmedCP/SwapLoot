# frozen_string_literal: true

# This class represents a Selling filter and is associated with a Steam account.
class SellingFilter < ApplicationRecord
  belongs_to :steam_account
  after_update :set_service_status

  def set_service_status
    service_type = self.class.name.gsub(/Filter$/, '').downcase
    steam_account&.trade_service&.update("#{service_type}_status".to_sym => false,
                                         "#{service_type}_job_id".to_sym => '')
  end
end
