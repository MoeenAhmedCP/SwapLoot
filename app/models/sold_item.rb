class SoldItem < ApplicationRecord
  belongs_to :steam_account
  scope :profits_by_year, ->(year) { where('EXTRACT(YEAR FROM date) = ?', year).group('EXTRACT(MONTH FROM date)').sum('(sold_price - bought_price)')}
  scope :quantity_by_year, ->(year) { where('EXTRACT(YEAR FROM date) = ?', year) }
end
