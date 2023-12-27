class SellableInventory < ApplicationRecord
  after_create :trigger_selling_job
  scope :inventory, ->(steam_account) { where(steam_id: steam_account.steam_id) }

  private

  def trigger_selling_job
    steam_account = SteamAccount.find_by(steam_id: self.steam_id)
    trade_service = TradeService.find_by(steam_account_id: steam_account.id)
    begin
      if trade_service.selling_status == true && trade_service.selling_job_id.present?
        selling_job_id = CsgoSellingJob.perform_async(steam_account.id)
        trade_service.update(selling_job_id: selling_job_id)
      end
      if trade_service.price_cutting_status == true && trade_service.price_cutting_job_id.present?
        price_cutting_job_id = PriceCuttingJob.perform_in(steam_account.selling_filter.undercutting_interval.minutes, steam_account.id)
        trade_service.update(price_cutting_job_id: price_cutting_job_id)
      end
    rescue StandardError => e
			report_api_error(e, [self&.class&.name, __method__.to_s])
    end
  end
end
