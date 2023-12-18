class SaveTransactionWorker
  include Sidekiq::Worker

  def perform(response, steam_account_id, headers)
    response = JSON.parse(response)
    last_page = response['last_page'].to_i
    (1..last_page).step(5).each do |page_number|
      (page_number..page_number + 4).each do |sub_page_number|
        SoldItemJob.perform_async(steam_account_id, sub_page_number, headers) unless sub_page_number > last_page
      end
      sleep(3)
    end
  end
end
