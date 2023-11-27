class SteamAccount < ApplicationRecord
  scope :active_account, -> { where(active: true) }
  
  belongs_to :user
  has_one :trade_service, dependent: :destroy
  has_one :selling_filter, dependent: :destroy
  has_one :buying_filter, dependent: :destroy
end
