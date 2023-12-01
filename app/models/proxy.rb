class Proxy < ApplicationRecord
  validates :ip, presence: true
  validates :port, presence: true
  validates :username, presence: true
  validates :password, presence: true
  belongs_to :steam_account
end
