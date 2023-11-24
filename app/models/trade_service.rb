# frozen_string_literal: true

# This class represents a Trade service and is associated with a Steam account.
class TradeService < ApplicationRecord
  belongs_to :steam_account
end
