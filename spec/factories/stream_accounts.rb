# spec/factories/steam_accounts.rb
FactoryBot.define do
  factory :steam_account do
    user
    unique_name { Faker::Name.name }
    steam_id { Faker::Number.number(digits: 17) }
    steam_web_api_key { Faker::Internet.password(min_length: 20, max_length: 50) }
    csgoempire_api_key { '' }
    # Add other attributes as needed
  end
end
