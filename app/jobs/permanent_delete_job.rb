class PermanentDeleteJob
	include Sidekiq::Job

  def perform
    p "<---------------- Permanent Delete Job Started --------------->"
    begin
      Inventory.soft_deleted_sold.where("sold_at < ?", Time.now - 30.days).destroy_all
      BidItem.where("created_at < ?", Time.now - 1.days).destroy_all
      Notification.where("created_at < ?", Time.now - 30.days).destroy_all
      Error.where("created_at < ?", Time.now - 14.days).destroy_all
    rescue
      PermanentDeleteJob.perform_in(2.minutes)
    end
  end
end