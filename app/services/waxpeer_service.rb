class WaxpeerService < ApplicationService
  include HTTParty

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @params = {
      api: @active_steam_account&.waxpeer_api_key
    }
  end

  def fetch_sold_items
    return [] if waxpeer_api_key_not_found?

    res = self.class.post(WAXPEER_BASE_URL + '/my-history', query: @params)
    item_sold = []

    if res['success'] == false
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      if res['data'].present?
        res['data']['trades'].each do |trade|
          if trade['action'] == 'sell'
            create_item(trade['item_id'], trade['name'], trade['give_amount'], trade['price'], trade['date'])
          end
        end
      end
    end
  end

  def create_item(id, market_name, b_price, s_price, date)
    item = Item.find_by(item_id: id)
    Item.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: @current_user.active_steam_account) unless item.present?
  end

  def fetch_item_listed_for_sale
    return [] if waxpeer_api_key_not_found?

    res = self.class.get(WAXPEER_BASE_URL + '/list-items-steam', query: @params)

    if res['success'] == false
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
      []
    else
      res['items']
    end
  end

  def fetch_balance
    return [] if waxpeer_api_key_not_found?

    res = self.class.get(WAXPEER_BASE_URL + '/user', query: @params)

    if res['success'] == false
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
      return 0
    else
      res['user']['wallet'].to_f / 1000
    end
  end

  def remove_item(item_id)
    return [] if waxpeer_api_key_not_found?

    res = self.class.get("#{BASE_URL}/remove-items", query: @params.merge(id: item_id))
    
    if res['success'] == false
      report_api_error(res&.keys&.at(1), [self&.class&.name, __method__.to_s])
    else
      res['removed'].count&.positive?
    end
  end

  def waxpeer_api_key_not_found?
    @active_steam_account&.waxpeer_api_key.blank?
  end
end
