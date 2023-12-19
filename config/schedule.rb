every 5.minutes do
  runner "SellableInventoryUpdationJob.perform_async", output: 'log/cron.log'
end
