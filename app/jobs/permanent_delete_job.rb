class PermanentDeleteJob < ApplicationJob
  queue_as :default

  def perform
    Inventory.soft_deleted_sold.where("sold_at < ?", Time.now - 30.days).destroy_all
    BidItems.where("created_at < ?", Time.now - 1.days).destroy_all
    Notifications.where("created_at < ?", Time.now - 30.days).destroy_all
    Errors.where("created_at < ?", Time.now - 14.days).destroy_all
    PermanentDeleteJob.set(wait_until: Time.now.tomorrow.beginning_of_day).perform_later
  end
end