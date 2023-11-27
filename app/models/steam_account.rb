class SteamAccount < ApplicationRecord
  scope :active_steam_account, ->(user) { find_by(active: true, user_id: user.id) }
  
  belongs_to :user
  has_one :trade_service, dependent: :destroy
  has_one :selling_filter, dependent: :destroy
  has_one :buying_filter, dependent: :destroy
end
