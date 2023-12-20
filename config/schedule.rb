every 5.minutes do
  runner "SellableInventoryUpdationJob.perform_async", output: 'log/cron.log'
end

every 1.day, at: '12:00 am' do
  runner "PermanentDeleteJob.perform_async"
  runner "PriceEmpireSuggestedPriceJob.perform_async"
end