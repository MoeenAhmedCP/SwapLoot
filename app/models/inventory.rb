class Inventory < ApplicationRecord
  scope :soft_deleted_sold, -> { where.not(sold_at: nil) }
  scope :steam_inventories, ->(active_steam_account) {
    where(steam_id: active_steam_account&.steam_id)
  }

  def soft_delete_and_set_sold_at
    update(sold_at: Time.current)
  end

  def self.fetch_inventory_for_user(user)
    csgo_service = CsgoempireService.new(user)
    csgo_service.fetch_my_inventory
  end
end
