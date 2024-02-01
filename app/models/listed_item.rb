class ListedItem < ApplicationRecord
  belongs_to :steam_account
  validates :item_id, uniqueness: true
end
