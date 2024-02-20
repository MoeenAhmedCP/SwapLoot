class PermanentDeleteJob
	include Sidekiq::Job
  sidekiq_options retry: false

  def perform
    p "<---------------- Permanent Delete Job Started --------------->"
    Inventory.soft_deleted_sold.where("sold_at < ?", Time.now - 30.days).destroy_all
    BidItem.where("created_at < ?", Time.now - 1.days).destroy_all
    Notification.where("created_at < ?", Time.now - 30.days).destroy_all
    Error.where("created_at < ?", Time.now - 14.days).destroy_all
  end
end