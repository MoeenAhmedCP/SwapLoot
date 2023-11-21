class PermanentDeleteJob < ApplicationJob
  queue_as :default

  def perform
    Inventory.soft_deleted_sold.where("sold_at < ?", Time.now - 30.days).destroy_all
    PermanentDeleteJob.set(wait_until: Time.now.tomorrow.beginning_of_day).perform_later
  end
end
