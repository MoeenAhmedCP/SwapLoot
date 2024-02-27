# frozen_string_literal: true

# This class represents a Trade service and is associated with a Steam account.
class TradeService < ApplicationRecord
  belongs_to :steam_account
  enum market_type: {
    csgo_empire: 0,
    waxpeer: 1,
    marketdotcsgo: 2
  }
end
