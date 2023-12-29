class Inventory < ApplicationRecord
  scope :soft_deleted_sold, -> { where.not(sold_at: nil) }
  scope :steam_inventories, ->(active_steam_account) {
    where(steam_id: active_steam_account&.steam_id)
  }
  scope :tradable_steam_inventories, ->(active_steam_account) {
    if active_steam_account.respond_to?(:each)
      where(steam_id: active_steam_account.map(&:steam_id), tradable: true)
    else
      where(steam_id: active_steam_account&.steam_id, tradable: true)
    end
  }
  scope :non_tradable_steam_inventories, ->(active_steam_account) {
    if active_steam_account.respond_to?(:each)
      where(steam_id: active_steam_account.map(&:steam_id), tradable: false)
    else
      where(steam_id: active_steam_account&.steam_id, tradable: false)
    end
  }

  def soft_delete_and_set_sold_at
    update(sold_at: Time.current)
  end

  def self.fetch_inventory_for_user(user)
    csgo_service = CsgoempireService.new(user)
    csgo_service.fetch_my_inventory
  end

  def self.ransackable_attributes(auth_object = nil)
    ["item_id", "market_name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
