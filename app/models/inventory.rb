class Inventory < ApplicationRecord
  validates :item_id, uniqueness: true
  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }
  scope :waxpeer_inventory, -> {where(market_type: "waxpeer")}
  scope :csgoempire_inventory, -> {where(market_type: "csgoempire")}
  scope :market_csgo_inventory, -> {where(market_type: "market_csgo")}
  scope :soft_deleted_sold, -> { where.not(sold_at: nil) }
  scope :steam_inventories, ->(active_steam_account) {
    where(steam_id: active_steam_account&.steam_id)
  }

  def soft_delete_and_set_sold_at
    update(sold_at: Time.current)
  end

  def self.fetch_inventory_for_user(user)
    csgo_service = CsgoempireService.new(user)
    csgo_service.update_ui_inventory
  end

  def self.ransackable_attributes(auth_object = nil)
    ["item_id", "market_name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
