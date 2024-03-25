# frozen_string_literal: true

# This class represents a Trade service and is associated with a Steam account.
class TradeService < ApplicationRecord
  belongs_to :steam_account
  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }

  scope :waxpeer_trade_service, -> { find_by(market_type: "waxpeer") }
  scope :csgoempire_trade_service, -> { find_by(market_type: "csgoempire") }
  scope :market_csgo_trade_service, -> { find_by(market_type: "market_csgo") }  
end
