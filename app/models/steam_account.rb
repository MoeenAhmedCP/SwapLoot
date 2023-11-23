class SteamAccount < ApplicationRecord
  belongs_to :user
  has_one :trade_service
  has_one :selling_filter
  has_one :buying_filter
end
