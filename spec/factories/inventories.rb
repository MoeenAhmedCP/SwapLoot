# == Schema Information
#
# Table name: inventories
#
#  id           :bigint           not null, primary key
#  item_id      :string
#  market_name  :string
#  market_price :integer
#  tradable     :boolean
#  steam_id     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# spec/factories/inventories.rb
FactoryBot.define do
  factory :inventory do
    # Add other attributes as needed
  end
end
