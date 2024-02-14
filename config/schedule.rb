every 1.day, at: ['12:00 am', '12:00 pm'] do
  runner "FetchInventoryJob.perform_async", output: 'log/cron.log'
end

every 1.day, at: '12:30 am' do
  runner "RecheckingItemsForSaleJob.perform_async", output: 'log/cron.log'
end

every 2.minutes do 
  runner "SidekiqStatusJob.perform_async", output: 'log/cron.log'
end

every 1.day, at: '12:00 am' do
  runner "SellableInventoryUpdationJob.perform_async", output: 'log/cron.log'
  runner "PermanentDeleteJob.perform_async", output: 'log/cron.log'
  runner "PriceEmpireSuggestedPriceJob.perform_async", output: 'log/cron.log'
end