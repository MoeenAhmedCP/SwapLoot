class SellableInventory < ApplicationRecord
  after_create :trigger_selling_job
  scope :inventory, ->(steam_account) { where(steam_id: steam_account.steam_id) }
  enum market_type: {
    csgoempire: 0,
    waxpeer: 1,
    market_csgo: 2
  }
  scope :waxpeer_inventory, -> {where(market_type: "waxpeer")}
  scope :csgoempire_inventory, -> {where(market_type: "csgoempire")}
  scope :market_csgo_inventory, -> {where(market_type: "market_csgo")}

  def self.csgoempire_steam_inventories
    where(market_type: "csgoempire")
  end

  def self.waxpeer_steam_inventories
    where(market_type: "waxpeer")
  end

  def self.market_csgo_steam_inventories
    where(market_type: "market_csgo")
  end

  def self.ransackable_attributes(auth_object = nil)
    ["item_id", "market_name"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def trigger_selling_job
    market_type = self.market_type
    steam_account = SteamAccount.find_by(steam_id: self.steam_id)
    trade_service = TradeService.find_by(steam_account_id: steam_account.id, market_type: market_type)
    begin
      case market_type
        when "csgoempire"
          if trade_service.selling_status == true && trade_service.selling_job_id.present?
            selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
            trade_service.update(selling_job_id: selling_job_id)
          end
          if trade_service.selling_status == true && trade_service.price_cutting_job_id.present?
            puts "Price Cutting from -> Sellable Inventory"
            price_cutting_job_id = PriceCuttingJob.perform_in(steam_account.selling_filters.csgoempire_filter.undercutting_interval.minutes, steam_account.id)
            trade_service.update(price_cutting_job_id: price_cutting_job_id)
          end
        when "waxpeer"
          if trade_service.selling_status == true && trade_service.selling_job_id.present?
            selling_job_id = WaxpeerSellingJob.perform_async(steam_account.id)
            trade_service.update(selling_job_id: selling_job_id)
          end
          if trade_service.selling_status == true && trade_service.price_cutting_job_id.present?
            price_cutting_job_id = WaxpeerPriceCuttingJob.perform_in(steam_account.selling_filters.csgoempire_filter.undercutting_interval.minutes, steam_account.id)
            trade_service.update(price_cutting_job_id: price_cutting_job_id)
          end
        when "market_csgo"
          if trade_service.selling_status == true && trade_service.selling_job_id.present?
            selling_job_id = MarketcsgoSellingJob.perform_async(steam_account.id)
            trade_service.update(selling_job_id: selling_job_id)
          end
          if trade_service.selling_status == true && trade_service.price_cutting_job_id.present?
            price_cutting_job_id = MarketcsgoPriceCuttingJob.perform_in(steam_account.selling_filters.csgoempire_filter.undercutting_interval.minutes, steam_account.id)
            trade_service.update(price_cutting_job_id: price_cutting_job_id)
          end
      end
    rescue StandardError => e
			report_api_error(e, [self&.class&.name, __method__.to_s])
    end
  end
end
