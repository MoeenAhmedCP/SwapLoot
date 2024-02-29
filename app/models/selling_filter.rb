# frozen_string_literal: true

# This class represents a Selling filter and is associated with a Steam account.
class SellingFilter < ApplicationRecord
  include DeleteEnqueuedJobsConcern

  belongs_to :steam_account
  after_update :set_service_status

  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }

  scope :csgoempire_filter, -> { find_by(market_type: "csgoempire") }
  scope :waxpeer_filter, -> { find_by(market_type: "waxpeer") }
  scope :market_csgo_filter, -> { find_by(market_type: "market_csgo") }

  def set_service_status
    trade_service = self.steam_account.trade_services.send("#{self.market_type}_trade_service")
    trade_service.update(selling_status: false)
    delete_enqueued_job(trade_service.selling_job_id)
  end
end
