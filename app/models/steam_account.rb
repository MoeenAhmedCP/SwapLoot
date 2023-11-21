class SteamAccount < ApplicationRecord
  belongs_to :user
  validates :unique_name, :steam_id, :steam_web_api_key, presence: true
end
