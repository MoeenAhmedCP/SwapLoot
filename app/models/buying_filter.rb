# frozen_string_literal: true

# This class represents a Buying filter and is associated with a Steam account.
class BuyingFilter < ApplicationRecord
  belongs_to :steam_account
  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }

  scope :csgoempire_filter, -> { find_by(market_type: "csgoempire") }
  scope :waxpeer_filter, -> { find_by(market_type: "waxpeer") }
  scope :market_csgo_filter, -> { find_by(market_type: "market_csgo") }
end
