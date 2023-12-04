class SteamAccount < ApplicationRecord
  scope :active_accounts, -> { where(active: true) }
  
  belongs_to :user
  has_one :trade_service, dependent: :destroy
  has_one :selling_filter, dependent: :destroy
  has_one :buying_filter, dependent: :destroy
  has_many :sold_items, dependent: :destroy
end
