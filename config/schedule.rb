# every 1.minute do
#   runner 'CsgoempireSellingService.new.sell_csgoempire', output: 'log/cron.log'
# end

every 1.day, at: '12:00 am' do
  runner 'CsgoempireSellingService.new.price_cutting_down_for_listed_items', output: 'log/cron.log'
end

