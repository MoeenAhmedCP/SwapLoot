# lib/tasks/deployment.rake
namespace :deploy do
  desc 'Set status of all jobs to false before deployment'
  task :stop_sidekiq_jobs => :environment do
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::DeadSet.new.clear
    TradeService.update_all(selling_status: false)
    TradeService.update_all(buying_status: false)
    TradeService.update_all(selling_job_id: false)
    TradeService.update_all(buying_job_id: false)
    TradeService.update_all(price_cutting_job_id: false)
    SteamAccount.all.each do |steam_account|
      RemoveItemListedForSaleJob.perform_async(steam_account.id)
    end
    puts "All Sidekiq jobs have been stopped."
  end
end

# lib/tasks/deployment.rake
namespace :deploy do
  desc 'Set status of all jobs to true after deployment'
  task :start_sidekiq_jobs => :environment do
    FetchInventoryJob.perform_async
    PriceEmpireSuggestedPriceJob.perform_async
    FetchSoldItemsMarketCsgoJob.perform_async
    SellableInventoryUpdationJob.perform_async
    puts "All Sidekiq jobs have been started."
  end
end
