class WaxpeerService < ApplicationService
  include HTTParty

  def initialize(current_user)
    @active_steam_account = current_user.active_steam_account
    @current_user = current_user
    @params = {
      api: @active_steam_account&.waxpeer_api_key
    }
  end

  def save_sold_item(res)
    if res['success'] == false
      report_api_error(res, [self&.class&.name, __method__.to_s])
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

  def fetch_sold_items
    if @active_steam_account.present?
      return [] if waxpeer_api_key_not_found?

      res = self.class.post(WAXPEER_BASE_URL + '/my-history', query: @params)
      save_sold_item(res)
    else
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.waxpeer_api_key.blank?

        res = self.class.post(WAXPEER_BASE_URL + '/my-history', query: site_params(steam_account))
        save_sold_item(res)
      end
    end
  end

  def create_item(id, market_name, b_price, s_price, date)
    item = SoldItem.find_by(item_id: id)
    SoldItem.create(item_id: id, item_name: market_name, bought_price: b_price, sold_price: s_price, date: date, steam_account: @active_steam_account) unless item.present?
  end

  def site_params(steam_account)
    { api: steam_account&.waxpeer_api_key }
  end

  def fetch_item_listed_for_sale
    if @active_steam_account.present?
      return [] if waxpeer_api_key_not_found?

      res = self.class.get(WAXPEER_BASE_URL + '/list-items-steam', query: @params)

      if res['success'] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        []
      else
        response = res['items'].present? ? res['items'] : []
      end
    else
      response = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.waxpeer_api_key.blank?

        res = self.class.get(WAXPEER_BASE_URL + '/list-items-steam', query: site_params(steam_account))
        response += res['items'].present? ? res['items'] : []
      end
    end
    response
  end

  def fetch_balance
    if @active_steam_account.present?
      return [] if waxpeer_api_key_not_found?

      res = self.class.get(WAXPEER_BASE_URL + '/user', query: @params)

      if res['success'] == false
        report_api_error(res, [self&.class&.name, __method__.to_s])
        return 0
      else
        res = self.class.get(WAXPEER_BASE_URL + '/user', query: @params)
        res['user'].present? ? res['user']['wallet'].to_f / 1000 : 0
      end
    else
      response_data = []
      @current_user.steam_accounts.each do |steam_account|
        next if steam_account&.waxpeer_api_key.blank?

        response = self.class.get(WAXPEER_BASE_URL + '/user', query: site_params(steam_account))
        response_hash = {
          account_id: steam_account.id,
          balance: response['user'].present? ? response['user']['wallet'].to_f / 1000 : 0
        }
        response_data << response_hash
      end
      response_data
    end
  end

  def remove_item(item_id)
    return [] if waxpeer_api_key_not_found?

    res = self.class.get("#{BASE_URL}/remove-items", query: @params.merge(id: item_id))

    if res['success'] == true
      res['removed'].count&.positive?
    end
  end

  def waxpeer_api_key_not_found?
    @active_steam_account&.waxpeer_api_key.blank?
  end
end
