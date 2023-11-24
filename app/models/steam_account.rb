class SteamAccount < ApplicationRecord
  scope :active_steam_account, ->(user) { find_by(active: true, user_id: user.id) }
  
  belongs_to :user
end
