class Inventory < ApplicationRecord
  has_many :missing_items
  scope :soft_deleted_sold, -> { where.not(sold_at: nil) }

  def soft_delete_and_set_sold_at
    update(sold_at: Time.current)
  end
end
