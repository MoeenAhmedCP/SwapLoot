module ItemSoldHelper
  def self.get_bought_price(item_id)
    Inventory.find_by(item_id: item_id)&.market_price
  end
end