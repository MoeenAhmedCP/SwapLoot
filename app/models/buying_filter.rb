# frozen_string_literal: true

# This class represents a Buying filter and is associated with a Steam account.
class BuyingFilter < ApplicationRecord
  belongs_to :steam_account
end
