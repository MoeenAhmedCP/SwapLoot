every 15.minutes do
  runner "SellableInventoryUpdationJob.perform_async", output: 'log/cron.log'
end
