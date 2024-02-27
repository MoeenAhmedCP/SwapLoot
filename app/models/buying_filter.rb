# frozen_string_literal: true

# This class represents a Buying filter and is associated with a Steam account.
class BuyingFilter < ApplicationRecord
  belongs_to :steam_account
  enum market_type: {
    csgo_empire: 0,
    waxpeer: 1,
    marketdotcsgo: 2
  }
end
