class SentReceivedItem < ApplicationRecord
  enum trade_type: {
    sell: 0,
    buy: 1
  }
end
