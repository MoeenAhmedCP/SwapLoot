# frozen_string_literal: true

# This class represents a Trade service and is associated with a Steam account.
class TradeService < ApplicationRecord
  belongs_to :steam_account
  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }

  def self.market_csgo_trade_service
    where(market_type: :market_csgo).first
  end

  def self.csgoempire_trade_service
    where(market_type: :csgoempire).first
  end

  def self.waxpeer_trade_service
    where(market_type: :waxpeer).first
  end
end
