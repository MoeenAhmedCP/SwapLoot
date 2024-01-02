class SoldItemHistory < ApplicationRecord
  include RansackObject
  belongs_to :steam_account

  def self.ransackable_attributes(auth_object = nil)
    %w[item_id item_name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[steam_account]
  end
end
