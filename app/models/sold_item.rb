class SoldItem < ApplicationRecord
  include RansackObject
  belongs_to :steam_account
  scope :profits_by_year, ->(year) { where('EXTRACT(YEAR FROM date) = ?', year).group('EXTRACT(MONTH FROM date)').sum('(sold_price - bought_price)')}
  scope :quantity_by_year, ->(year) { where('EXTRACT(YEAR FROM date) = ?', year) }

  def self.ransackable_attributes(auth_object = nil)
    %w[item_id item_name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[steam_account]
  end
end
